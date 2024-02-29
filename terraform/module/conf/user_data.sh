#!/bin/bash
sudo apt -y update
sudo apt -y upgrade

## install util package
sudo apt -y install curl unzip

## install ssm agent
mkdir /tmp/ssm
curl https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb -o /tmp/ssm
sudo dpkg -i /tmp/ssm/amazon-ssm-agent.deb
sudo systemctl enable amazon-ssm-agent

## start ssm agent
systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

## aws cli install
mkdir /tmp/aws-cli
curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/aws-cli/awscliv2.zip
sudo unzip /tmp/aws-cli/awscliv2.zip -d /tmp/aws-cli
sudo /tmp/aws-cli/aws/install

## aws cli set completer
sudo echo "AWS_COMPLETER=$(which aws_completer)" >> /home/ubuntu/.bashrc
sudo echo "complete -C \"$AWS_COMPLETER\" aws" >> /home/ubuntu/.bashrc

## set hostname
instance_id=""
tag_name=""
hostname=""
hostname_count=0
count=0

while [ "$hostname_count" -eq 0 ] && [ "$count" -lt 10 ]
do
  instance_id=$(TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600") && curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id)
  tag_name=$(aws ec2 describe-instances \
                    --instance-id "$instance_id" \
                    --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value' \
                    --output text)
  hostname=${tag_name#*-}
  hostname_count=$(echo -n "$hostname" | wc -c)
  count=$((count += 1))
done

sudo hostnamectl set-hostname "$hostname"
