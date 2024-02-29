# EC2 グローバルIP
output "instance_public_ips" {
  value = { for node in aws_instance.node : node.tags["Name"] => "${node.public_ip}" }
  description = "The public IP addresses of the instances."
}
# SSH接続 コマンド
output "ssh_command" {
  value = { for node in aws_instance.node : node.tags["Name"] => "ssh -i ${var.private_ssh_key_name} ${var.os_user}@${node.public_ip}" }
  description = "The public IP addresses of the instances."
}
