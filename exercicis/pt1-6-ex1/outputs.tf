# outputs.tf

data "template_file" "ssh_config_template" {
  template = file("${path.module}/ssh_config.tpl")
  
  vars = {
    bastion_host_ip    = aws_eip.bastion_eip.public_ip
    bastion_user       = "ubuntu" # Asumiendo Ubuntu AMI
    bastion_key_file   = "~/.ssh/bastion.pem"
    
    private_instances  = jsonencode([
      for i in range(var.private_instance_count) : {
        hostname  = "private-${i + 1}"
        private_ip = aws_instance.private[i].private_ip
        key_file   = "~/.ssh/private-${i + 1}.pem"
      }
    ])
  }
}

resource "local_file" "ssh_config_output" {
  content  = data.template_file.ssh_config_template.rendered
  filename = "ssh_config_per_connectar.txt"
}

output "bastion_public_ip" {
  description = "IP pública del Bastion Host (Elástica)."
  value       = aws_eip.bastion_eip.public_ip
}