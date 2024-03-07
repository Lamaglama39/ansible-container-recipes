# 信頼ポリシー
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAMロール
resource "aws_iam_role" "role" {
  name               = "${var.base_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(
    {
      "Name" = "${var.base_name}-role"
    },
    var.tags
  )

}

# SSM用 IAMポリシー
data "aws_iam_policy" "systems_manager" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "systems_manager" {
  role       = aws_iam_role.role.name
  policy_arn = data.aws_iam_policy.systems_manager.arn
}

# EC2参照用 IAMポリシー
resource "aws_iam_policy" "ec2_describe" {
  name = "${var.base_name}-ec2-describe"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_describe" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.ec2_describe.arn
}

# インスタンスプロファイル
resource "aws_iam_instance_profile" "node" {
  name = "${var.base_name}-instance-profile"
  role = aws_iam_role.role.name
}
