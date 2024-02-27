# セキュリティグループ
resource "aws_security_group" "sg" {
  name        = "${var.base_name}-sg"
  description = "for swarm instances"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    {
      "Name" = "${var.base_name}-sg"
    },
    var.tags
  )

}

# インバウンドルール
resource "aws_security_group_rule" "ssh" {
  count = length(var.allow_ssh_cidrs) != 0 ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.sg.id
  cidr_blocks       = var.allow_ssh_cidrs
  description       = "ssh"
}

resource "aws_security_group_rule" "sg_rule" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.sg.id
  self              = true
  description       = "internal"
}
