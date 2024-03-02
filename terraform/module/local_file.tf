locals {
  master_leader_ips = { for name, instance in aws_instance.node : name => instance.public_ip if name == "master-001" }
  master_other_ips  = { for name, instance in aws_instance.node : name => instance.public_ip if substr(name, 0, 7) == "master-" && name != "master-001" }
  worker_ips        = { for name, instance in aws_instance.node : name => instance.public_ip if substr(name, 0, 7) ==  "worker-" }
}

resource "local_file" "ansible_inventory" {
  content  = templatefile("../../terraform/module/conf/ansible_inventory.tpl", {
    user_name           = var.os_user
    key_path            = var.private_ssh_key_name
    ip_address_master_001 = lookup(local.master_leader_ips, "master-001", "default_ip_or_empty_string")
    ip_address_master_002 = lookup(local.master_other_ips, "master-002", "default_ip_or_empty_string")
    ip_address_master_003 = lookup(local.master_other_ips, "master-003", "default_ip_or_empty_string")
    ip_address_worker_001 = lookup(local.worker_ips, "worker-001", "default_ip_or_empty_string")
    ip_address_worker_002 = lookup(local.worker_ips, "worker-002", "default_ip_or_empty_string")
  })
  filename = "../../ansible/hosts/ansible_inventory.yml"

  depends_on = [ aws_instance.node ]
}