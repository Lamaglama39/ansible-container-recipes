all:
  vars:
    ansible_user: "${user_name}"
    ansible_ssh_private_key_file: ".ssh/${key_path}"
  children:
    master_leader:
      hosts:
        master-001:
          ansible_host: "${ip_address_master_001}"
    master_other:
      hosts:
        master-002:
          ansible_host: "${ip_address_master_002}"
        master-003:
          ansible_host: "${ip_address_master_003}"
    worker:
      hosts:
        worker-001:
          ansible_host: "${ip_address_worker_001}"
        worker-002:
          ansible_host: "${ip_address_worker_002}"
