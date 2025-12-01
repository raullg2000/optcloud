# ssh_config.tpl
# START: Configuració Terraform ProxyJump

# Configuración del Bastion Host
Host bastion
  HostName ${bastion_host_ip}
  User ${bastion_user}
  IdentityFile ${bastion_key_file}
  
# Configuración de las Instancias Privadas
%{ for instance in jsondecode(private_instances) ~}
Host ${instance.hostname}
  HostName ${instance.private_ip}
  User ${bastion_user}
  IdentityFile ${instance.key_file}
  ProxyJump ${bastion_user}@${bastion_host_ip}
%{ endfor ~}

# END: Configuració Terraform ProxyJump