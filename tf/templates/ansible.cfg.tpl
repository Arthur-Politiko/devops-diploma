[defaults]
inventory = inventory.ini
host_key_checking = False
retry_files_enabled = False

[ssh_connection]
pipelining = True
ssh_args = -o ConnectTimeout=8 -o BatchMode=yes -o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh  -i ../vault/id_ed25519 -o StrictHostKeyChecking=no -W %h:%p ${bastion_user}@${bastion_ip}"

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
