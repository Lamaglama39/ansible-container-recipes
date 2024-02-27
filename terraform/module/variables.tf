# Common
variable "base_name" {
  description = "PJ名+環境名"
  type        = string
}

variable "tags" {
  description = "各リソース タグ"
  type        = map(string)
}

# Network
variable "vpc_cidr" {
  description = "VPC CIDRブロック"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet CIDRブロック"
  type        = string
}

# EC2
variable "nodes" {
  description = "ノード名一覧"
  type        = list(string)
}

variable "instance_type" {
  description = "インスタンスタイプ"
  type        = string
}

# キーペア
variable "private_ssh_key_name" {
  description = "キーペア用秘密鍵"
  type        = string
}

variable "public_ssh_key_name" {
  description = "キーペア用公開鍵"
  type        = string
}

variable "key_pair_name" {
  description = "キーペア名"
  type        = string
}

# セキュリティグループ
variable "allow_ssh_cidrs" {
  description = "SSH接続を許可する送信元IPアドレス"
  type        = list(string)
}
