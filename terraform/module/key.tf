# ssh key 作成
resource "tls_private_key" "keygen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  filename = "../../ansible/.ssh/${var.private_ssh_key_name}"
  content  = tls_private_key.keygen.private_key_pem
  provisioner "local-exec" {
    command = "chmod 600 ../../ansible/.ssh/${var.private_ssh_key_name}"
  }
}

resource "local_file" "public_key_openssh" {
  filename = "../../ansible/.ssh/${var.public_ssh_key_name}"
  content  = tls_private_key.keygen.public_key_openssh
  provisioner "local-exec" {
    command = "chmod 600 ../../ansible/.ssh/${var.public_ssh_key_name}"
  }
}

resource "null_resource" "copy_ssh_keys" {
  depends_on = [local_file.private_key_pem, local_file.public_key_openssh]

  provisioner "local-exec" {
    command = "mkdir -p ./.ssh && cp -r ../../ansible/.ssh/* ./.ssh/ "
  }
}

# key pair 作成
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.keygen.public_key_openssh
}
