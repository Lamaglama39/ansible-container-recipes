# SSH接続 コマンド
output "instance_public_ips" {
  value = { for node in aws_instance.node : node.tags["Name"] => "ssh -i ${var.private_ssh_key_name} ubuntu@${node.public_ip}" }
  description = "The public IP addresses of the instances."
}
