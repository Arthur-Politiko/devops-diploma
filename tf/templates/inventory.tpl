[all:vars]
ansible_user=${user_name}
ansible_ssh_private_key_file=${private_key_path}
master_name=${master.name}
master_ip=${master.ip}
registry_id=${registry_id}

[masters]

%{~ for m in master_ips ~}
${m.name} ansible_host=${m.ip}
%{endfor}
    
[workers] 

%{~ for w in worker_ips ~}
${w.name} ansible_host=${w.ip}
%{endfor}

[nat_gateway]

%{~ for n in nat_ips ~}
${n.name} ansible_host=${n.ip}
%{endfor}

[admin]

%{~ for m in admin_ips ~}
${m.name} ansible_host=${m.ip}
%{endfor}

[all:children]
masters
workers
nat_gateway
admin