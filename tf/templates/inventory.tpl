[all:vars]
ansible_user=${user_name}
ansible_ssh_private_key_file=${private_key_path}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[master]

%{~ for name, ip in master_ips ~}
${name} ansible_host=${ip}
%{endfor}
    
[workers] 

%{~ for name, ip in worker_ips ~}
${name} ansible_host=${ip}
%{endfor}

[all:children]
master
workers