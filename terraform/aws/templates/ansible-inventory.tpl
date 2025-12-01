[wireguard_servers]
${instance_id} ansible_host=${instance_ip} ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3

[wireguard_servers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
