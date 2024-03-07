# リージョン
provider "aws" {
  region = "ap-northeast-1"
}

# terraform実行元 パブリックIP
data "http" "ipv4_icanhazip" {
  url = "http://ipv4.icanhazip.com/"
}

locals {
  # common parameter
  ## タグ
  pj  = "container"
  env = "terraform"

  tags = {
    pj  = local.pj
    env = local.env
  }

  # Network
  ## VPC CIDR
  vpc_cidr = "192.168.0.0/16"
  ## subnet CIDR
  subnet_cidr = "192.168.0.0/24"

  # EC2
  ## OSユーザー
  os_user = "ubuntu"
  ## EC2 ノード一覧
  nodes = ["master-001", "master-002", "master-003", "worker-001", "worker-002"]
  ## インスタンスタイプ
  instance_type = "t3.medium"

  # EC2用キーペア
  ## SSHキー
  private_ssh_key_name = "ansible_key"
  public_ssh_key_name  = "ansible_key.pub"
  ## キーペア
  key_pair_name = "key_pair_name"

  # SecurityGroup
  ## SSH接続用 送信元グローバルIP
  current-ip      = chomp(data.http.ipv4_icanhazip.body)
  allow_ssh_cidrs = ["${local.current-ip}/32"]

}

module "main" {
  source = "../module"

  # tag
  base_name = local.pj
  tags      = local.tags

  # Network
  vpc_cidr    = local.vpc_cidr
  subnet_cidr = local.subnet_cidr

  # EC2
  os_user              = local.os_user
  nodes                = local.nodes
  instance_type        = local.instance_type
  private_ssh_key_name = local.private_ssh_key_name
  public_ssh_key_name  = local.public_ssh_key_name
  key_pair_name        = local.key_pair_name

  allow_ssh_cidrs = local.allow_ssh_cidrs

}
