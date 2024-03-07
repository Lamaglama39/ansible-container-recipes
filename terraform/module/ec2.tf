# AMI

## Ubuntu18.04 最新AMI
data "aws_ami" "ubuntu18" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}
## Ubuntu20.04 最新AMI
data "aws_ami" "ubuntu20" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
## Ubuntu22.04 最新AMI
data "aws_ami" "ubuntu22" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
## Ubuntu23.04 最新AMI
data "aws_ami" "ubuntu23" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-lunar-23.04-amd64-server-*"]
  }
}

# インスタンス
resource "aws_instance" "node" {
  for_each = toset(var.nodes)

  ami                         = data.aws_ami.ubuntu23.id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.node.name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  user_data                   = file("../../terraform/module/conf/user_data.sh")
  key_name                    = var.key_pair_name

  tags = merge(
    {
      "Name" = "${each.value}"
    },
    var.tags
  )

}