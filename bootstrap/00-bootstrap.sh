#!/bin/bash

set -euo pipefail

# Пути считаем от самого скрипта, а не от текущего каталога: запускать его
# можно и из корня репозитория, и из bootstrap/.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ORG_ID="bpfuhii9ok1q5hhitspn"
CLOUD_ID="b1gguv60gg3mvfac0ql6"
FOLDER_NAME=devops-diploma
FOLDER_ID=""
SA_NAME=diploma-sa
SA_KEY="$REPO_ROOT/vault/diploma-sa-key.json"
SA_ID=""
SSH_KEY_DIR="$REPO_ROOT/vault"
SSH_KEY_NAME=id_ed25519
OSLOGIN_LOGIN=ubuntu
OSLOGIN_UID=2000
OSLOGIN_HOME=/home/ubuntu
OSLOGIN_SHELL=/bin/bash
SSH_KEY_EXPIRES_AT="2027-01-01T00:00:00Z"

SUCCESS=0
GENERAL_ERROR=1
MISUSE=2
NOT_FOUND=3


function get_cell() {
  local row_delim="+"
  local col_delim="|"
  local x=$1
  local y=$2
  local table="$3"
  local colcount=$(( $(echo "$table" | sed -n '2{s/[^'"$col_delim"']//g; p}' | wc -m) - 2))
  local rowcount=$(( $(echo "$table" | sed -n '/'"$row_delim"'/=' | wc -l) - 2))
  declare -A data
  declare -A ldata

  for j in `seq $rowcount` ; do
    for i in `seq $colcount` ; do
      data["$i,$j"]=$(echo "$table" | sed -n "$((j+3)){s/$col_delim/ /g;p}" | awk -v col=$i '{print $col}')
    #   echo "[$i,$j]=$s"
    done
  done
  echo "${data["$x,$y"]}"
}

function get_folder_id_by_name() {
  result=$(yc resource-manager folder list | awk -v name="$1" '{ if ($4 == name) {print $2} }'   && sleep 10)
  if [ -z "$result" ]; then
    # echo "Folder $1 not found"
    return $NOT_FOUND
  fi
  echo "$result"
}

function create_folder() {
  result=$(yc resource-manager folder create --name "$1" | awk '{ if ($1 == "id:") {print $2} }' && sleep 10)
  if [ -z "$result" ]; then
    # echo "Failed to create folder $1"
    return $GENERAL_ERROR
  fi
  echo "$result"
}

function get_folder_sa() {
  result=$(yc iam service-account list --folder-id "$1" | sed -n '4p' | awk '{print $2}'  && sleep 10)
  if [ -z "$result" ]; then
    # echo "Service account $2 not found in folder $1"
    return $NOT_FOUND
  fi
  echo "$result"
}

function create_folder_sa() {
  result=$(yc iam service-account create --name "$2" --folder-id "$1" | awk '{ if ($1 == "id:") {print $2} }' && sleep 10)
  if [ -z "$result" ]; then
    # echo "Failed to create service account $2 in folder $1"
    return $GENERAL_ERROR
  fi
  echo "$result"
}

function grant_folder_sa_access() {
  local folder_id=$1
  local sa_id=$2
  if [ -z "$folder_id" ] || [ -z "$sa_id" ]; then
    # echo "Folder ID and Service Account ID are required"
    return $MISUSE
  fi
  yc resource-manager folder add-access-binding \
    --id "$folder_id" \
    --role admin \
    --service-account-id "$sa_id"
}

function create_or_get_folder_id_by_name() {
  local name=$1
  if ! folder_id=$(get_folder_id_by_name "$name"); then
    # echo "Creating folder $name"
    folder_id=$(create_folder "$name")
  fi
  echo "$folder_id"
}

function create_or_get_folder_sa() {
  local folder_id=$1
  local sa_name=$2
  if ! sa_id=$(get_folder_sa "$folder_id" "$sa_name"); then
    # echo "Creating service account $sa_name in folder $folder_id"
    sa_id=$(create_folder_sa "$folder_id" "$sa_name")
  fi
  echo "$sa_id"
}

function create_or_get_ssh() {
  local key_dir=$1
  local key_name=$2
  mkdir -p "$key_dir"
  if [ ! -f "${key_dir}/${key_name}" ]; then
    ssh-keygen -t ed25519 -f "${key_dir}/${key_name}" -N ""
    echo "SSH key generated at ${key_dir}/${key_name}"
  else
    echo "SSH key ${key_dir}/${key_name} already exists, skipping generation"
  fi
}

function add_ssh_to_cloud() {
  local key_path=$1
  local key_name=$2
  yc organization-manager oslogin user-ssh-key create \
    --organization-id "$ORG_ID" \
    --subject-id "$SA_ID" \
    --name "$key_name" \
    --data "$(cat "${key_path}.pub")" \
    --expires-at "$SSH_KEY_EXPIRES_AT"
}

function create_oslogin_profile() {
  local subject_id=$1
  local login=$2
  local uid=$3
  local home_dir=$4
  local shell=$5
  if ! yc organization-manager oslogin profile create \
    --organization-id "$ORG_ID" \
    --subject-id "$subject_id" \
    --login "$login" \
    --uid "$uid" \
    --home-directory "$home_dir" \
    --shell "$shell"; then
    echo "OS Login profile '$login' may already exist, continuing"
  fi
}

function generate_service_account_key() {
  local sa_id=$1
  if [ -z "$sa_id" ]; then
    # echo "Service Account ID is required"
    return $MISUSE
  fi
  yc iam key create --service-account-id "$sa_id" --output "$SA_KEY" && sleep 10
}

# tfvars для bootstrap/: organization_id этому модулю не нужен — переменной
# с таким именем в bootstrap/00-variables.tf нет, и лишний ключ terraform
# отвергнет. Путь к ключу — относительно каталога bootstrap/.
function write_bootstrap_tfvars() {
  local folder_id=$1
  local sa_id=$2

  cat > "$SCRIPT_DIR/terraform.tfvars" <<EOL
cloud_id    = "$CLOUD_ID"
folder_id   = "$folder_id"
sa_id       = "$sa_id"
sa_key_file = "../vault/diploma-sa-key.json"
EOL
}

# tfvars для основной конфигурации: ей нужен organization_id.
function write_tf_tfvars() {
  local folder_id=$1
  local sa_id=$2

  cat > "$REPO_ROOT/tf/terraform.tfvars" <<EOL
organization_id = "$ORG_ID"
cloud_id        = "$CLOUD_ID"
folder_id       = "$folder_id"
sa_id           = "$sa_id"
sa_key_file     = "../vault/diploma-sa-key.json"
EOL
}

# ==========================

if ! FOLDER_ID="$(create_or_get_folder_id_by_name "$FOLDER_NAME")"; then
  echo "Failed to get or create folder $FOLDER_NAME"
  exit 1
else
  echo "Folder ID: $FOLDER_ID"
fi

if ! SA_ID="$(create_or_get_folder_sa "$FOLDER_ID" "$SA_NAME")"; then
  echo "Failed to get or create service account $SA_NAME in folder $FOLDER_NAME"
  exit 1
else
  echo "Service Account ID: $SA_ID"
fi

if ! grant_folder_sa_access "$FOLDER_ID" "$SA_ID"; then
  echo "Failed to grant access to service account $SA_NAME in folder $FOLDER_NAME"
  exit 1
else
  echo "Access granted to service account $SA_NAME in folder $FOLDER_NAME"
fi

# Generate and register SSH key pair at organization level (requires personal token)
if ! create_or_get_ssh "$SSH_KEY_DIR" "$SSH_KEY_NAME"; then
  echo "Failed to create SSH key"
  exit 1
fi

if ! add_ssh_to_cloud "${SSH_KEY_DIR}/${SSH_KEY_NAME}" "$SSH_KEY_NAME"; then
  echo "Failed to add SSH key to cloud"
  exit 1
else
  echo "SSH key registered at org level for SA $SA_NAME"
fi

if ! create_oslogin_profile "$SA_ID" "$OSLOGIN_LOGIN" "$OSLOGIN_UID" "$OSLOGIN_HOME" "$OSLOGIN_SHELL"; then
  echo "Failed to create OS Login profile"
  exit 1
else
  echo "OS Login profile '$OSLOGIN_LOGIN' ready for SA $SA_NAME"
fi

if ! generate_service_account_key "$SA_ID"; then
  echo "Failed to generate key for service account $SA_NAME"
  exit 1
else
  echo "Service account key generated at $SA_KEY"
fi

if ! write_bootstrap_tfvars "$FOLDER_ID" "$SA_ID"; then
  echo "Failed to write $SCRIPT_DIR/terraform.tfvars"
  exit 1
fi

if ! write_tf_tfvars "$FOLDER_ID" "$SA_ID"; then
  echo "Failed to write $REPO_ROOT/tf/terraform.tfvars"
  exit 1
fi
echo "terraform.tfvars записаны: bootstrap/terraform.tfvars и tf/terraform.tfvars"
