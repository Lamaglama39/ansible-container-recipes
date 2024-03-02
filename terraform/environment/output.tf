# EC2 グローバルIP
output "instance_public_ips" {
  value = module.main.instance_public_ips
}
# SSH接続 コマンド
output "ssh_command" {
  value = module.main.ssh_command
}