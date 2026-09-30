#!/usr/bin/env bash
#
# Настройка TeamCity для инфраструктурного пайплайна terraform (раздел 6 roadmap).
#
# Скрипт идемпотентен: повторный запуск приводит конфигурацию к нужному виду,
# а не создаёт дубликаты. Так конфигурация сборки перестаёт быть «сделанной
# руками в UI» и воспроизводится одной командой после пересборки стенда.
#
# Использование:
#   ./ci/teamcity-setup.sh           # сборка только планирует
#   APPLY=1 ./ci/teamcity-setup.sh   # сборка планирует и применяет
#
# Требуется:
#   - vault/teamcity_admin_password
#   - доступ к серверу TeamCity (по умолчанию http://ci.debugmonkey.ru)
#   - на admin-ноде разложены /home/ubuntu/{ci.tfvars,terraformrc,tf-sa-key.json,s3_key}
#     и смонтированы в агент (ansible/32-ci.yaml)
#
# ВАЖНО про формат запросов: TeamCity 2026.2 отвечает HTTP 500
# «IllegalArgumentException: argument type mismatch» на XML-тела запросов
# (в логе — teamcity-rest.log, а клиенту отдаётся страница maintenance-welcome,
# что сбивает с толку). Поэтому все изменяющие запросы здесь отправляются JSON.

set -euo pipefail

BASE="${TEAMCITY_URL:-http://ci.debugmonkey.ru}"
PROJECT_ID="Infra"
PROJECT_NAME="Infra"
VCS_ROOT_ID="devops_diploma_github"
VCS_ROOT_NAME="devops-diploma github"
VCS_URL="https://github.com/Arthur-Politiko/devops-diploma.git"
BUILD_TYPE_ID="Terraform_Apply"
BUILD_TYPE_NAME="Terraform apply (devops-diploma)"
APPLY="${APPLY:-0}"

export TC_PROJECT_ID="$PROJECT_ID" TC_PROJECT_NAME="$PROJECT_NAME"
export TC_VCS_ROOT_ID="$VCS_ROOT_ID" TC_VCS_ROOT_NAME="$VCS_ROOT_NAME" TC_VCS_URL="$VCS_URL"
export TC_BUILD_TYPE_ID="$BUILD_TYPE_ID" TC_BUILD_TYPE_NAME="$BUILD_TYPE_NAME"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASSWORD_FILE="$REPO_ROOT/vault/teamcity_admin_password"
JAR="$(mktemp)"
TMP_JSON="$(mktemp)"
trap 'rm -f "$JAR" "$TMP_JSON"' EXIT

[ -f "$PASSWORD_FILE" ] || { echo "Не найден $PASSWORD_FILE" >&2; exit 1; }
TC_PASS="$(cat "$PASSWORD_FILE")"

# --- сессия и CSRF-токен: изменяющие запросы TeamCity без него не принимает ---
curl -s -c "$JAR" -u "admin:$TC_PASS" "$BASE/" -o /dev/null
CSRF="$(curl -s -b "$JAR" -c "$JAR" -u "admin:$TC_PASS" "$BASE/authenticationTest.html?csrf" | tr -d '\r\n')"
[ -n "$CSRF" ] || { echo "Не удалось получить CSRF-токен" >&2; exit 1; }

# api METHOD PATH [FILE] — печатает тело ответа, падает при HTTP >= 400
api() {
  local method="$1" path="$2" file="${3:-}"
  local args=(-s -b "$JAR" -u "admin:$TC_PASS" -H "X-TC-CSRF-Token: $CSRF"
              -H "Content-Type: application/json" -H "Accept: application/json"
              -X "$method" -w $'\n%{http_code}')
  [ -n "$file" ] && args+=(--data-binary "@$file")
  local out; out="$(curl "${args[@]}" "$BASE$path")"
  local code="${out##*$'\n'}"
  echo "${out%$'\n'*}"
  [ "$code" -lt 400 ] || { echo "HTTP $code на $method $path" >&2; return 1; }
}

exists() {
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' -b "$JAR" -u "admin:$TC_PASS" -H 'Accept: application/json' "$BASE$1")"
  [ "$code" = "200" ]
}

# --- проект ---
if exists "/app/rest/projects/id:$PROJECT_ID"; then
  echo "проект $PROJECT_ID уже есть"
else
  python3 - <<'PY' > "$TMP_JSON"
import json, os
print(json.dumps({"id": os.environ["TC_PROJECT_ID"],
                  "name": os.environ["TC_PROJECT_NAME"],
                  "parentProjectId": "_Root"}))
PY
  api POST /app/rest/projects "$TMP_JSON" >/dev/null
  echo "проект $PROJECT_ID создан"
fi

# --- VCS root ---
if exists "/app/rest/vcs-roots/id:$VCS_ROOT_ID"; then
  echo "VCS root $VCS_ROOT_ID уже есть"
else
  python3 - <<'PY' > "$TMP_JSON"
import json, os
e = os.environ
props = [("url", e["TC_VCS_URL"]), ("branch", "refs/heads/main"),
         ("authMethod", "ANONYMOUS"), ("usernameStyle", "USERID"),
         ("teamcity:branchSpec", "+:refs/heads/*")]
print(json.dumps({
    "id": e["TC_VCS_ROOT_ID"],
    "name": e["TC_VCS_ROOT_NAME"],
    "vcsName": "jetbrains.git",
    "project": {"id": e["TC_PROJECT_ID"]},
    "properties": {"property": [{"name": n, "value": v} for n, v in props]},
}))
PY
  api POST /app/rest/vcs-roots "$TMP_JSON" >/dev/null
  echo "VCS root $VCS_ROOT_ID создан"
fi

# --- сборка ---
# Внимание: <checkout-rules/> обязателен, иначе TeamCity отвечает 200, но
# привязка VCS root к сборке не создаётся и ни один триггер не работает.
if exists "/app/rest/buildTypes/id:$BUILD_TYPE_ID"; then
  echo "сборка $BUILD_TYPE_ID уже есть"
else
  python3 - <<'PY' > "$TMP_JSON"
import json, os
e = os.environ
print(json.dumps({
    "id": e["TC_BUILD_TYPE_ID"],
    "name": e["TC_BUILD_TYPE_NAME"],
    "project": {"id": e["TC_PROJECT_ID"]},
    "vcs-root-entries": {"vcs-root-entry": [{
        "id": e["TC_VCS_ROOT_ID"],
        "vcs-root": {"id": e["TC_VCS_ROOT_ID"]},
        "checkout-rules": "",
    }]},
    # ansible.cfg и inventory.ini генерирует terraform (local_file) уже внутри
    # чекаута сборки, поэтому публикуем их артефактами — иначе на ноутбук
    # оператора после apply в CI они не попадут.
    "settings": {"property": [
        {"name": "artifactRules", "value": "ansible/ansible.cfg\nansible/inventory.ini"},
    ]},
}))
PY
  api POST /app/rest/buildTypes "$TMP_JSON" >/dev/null
  echo "сборка $BUILD_TYPE_ID создана"
fi

# --- шаг сборки ---
STEP_SCRIPT="$(cat <<'SCRIPT'
set -e
cd tf

# Ключи бэкенда: в блоке backend "s3" их нет, поэтому terraform берёт AWS_*
# из окружения. Файл формата "key_id <значение>" / "secret <значение>".
export AWS_ACCESS_KEY_ID=$(awk '$1=="key_id"{print $2}' /keys/s3_key)
export AWS_SECRET_ACCESS_KEY=$(awk '$1=="secret"{print $2}' /keys/s3_key)

terraform fmt -check -recursive
terraform init -no-color
terraform validate -no-color
terraform plan -var-file=/keys/ci.tfvars -no-color -out=tfplan
SCRIPT
)"
if [ "$APPLY" = "1" ]; then
  STEP_SCRIPT="$STEP_SCRIPT
terraform apply -auto-approve -no-color tfplan"
else
  STEP_SCRIPT="$STEP_SCRIPT
echo 'apply отключён: сборка только планирует (запусти скрипт с APPLY=1, чтобы включить)'"
fi
export STEP_SCRIPT

STEP_ID="$(curl -s -H 'Accept: application/json' -b "$JAR" -u "admin:$TC_PASS" \
  "$BASE/app/rest/buildTypes/id:$BUILD_TYPE_ID/steps" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); s=d.get("step") or []; print(s[0]["id"] if s else "")')"
export STEP_ID

python3 - <<'PY' > "$TMP_JSON"
import json, os
step = {
    "name": "Terraform plan/apply",
    "type": "simpleRunner",
    "properties": {"property": [
        {"name": "script.content", "value": os.environ["STEP_SCRIPT"]},
        {"name": "use.custom.script", "value": "true"},
    ]},
}
if os.environ.get("STEP_ID"):
    step["id"] = os.environ["STEP_ID"]
print(json.dumps(step))
PY

if [ -n "$STEP_ID" ]; then
  api PUT "/app/rest/buildTypes/id:$BUILD_TYPE_ID/steps/$STEP_ID" "$TMP_JSON" >/dev/null
  echo "шаг сборки обновлён (APPLY=$APPLY)"
else
  api POST "/app/rest/buildTypes/id:$BUILD_TYPE_ID/steps" "$TMP_JSON" >/dev/null
  echo "шаг сборки создан (APPLY=$APPLY)"
fi

# --- триггер ---
if curl -s -H 'Accept: application/json' -b "$JAR" -u "admin:$TC_PASS" \
     "$BASE/app/rest/buildTypes/id:$BUILD_TYPE_ID/triggers" | grep -q '"+:main"'; then
  echo "триггер уже настроен на +:main"
else
  python3 - <<'PY' > "$TMP_JSON"
import json
print(json.dumps({
    "type": "vcsTrigger",
    "properties": {"property": [
        {"name": "branchFilter", "value": "+:main"},
        {"name": "quietPeriodMode", "value": "DO_NOT_USE"},
    ]},
}))
PY
  api POST "/app/rest/buildTypes/id:$BUILD_TYPE_ID/triggers" "$TMP_JSON" >/dev/null
  echo "триггер создан: коммит в main запускает сборку"
fi

echo
echo "Готово. Сборка: $BASE/buildConfiguration/$BUILD_TYPE_ID"
