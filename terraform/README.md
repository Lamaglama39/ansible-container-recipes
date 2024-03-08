# terraform
コンテナオーケストレーション環境を実装するためにAWSでインスタンスを作成する terraform です。  
デフォルトでマスターノード用に3台、ワーカーノード用に2台の5台構成となりますが、  
必要に応じて後述の設定で増減できます。


## ■ 前提条件
Terraform 実行にあたり、以下が前提条件となります。  
未導入の場合は記載の公式ドキュメントを参考に設定してください。

* Terraform をインストールしていること  
  ➤ [Terraform インストール](https://developer.hashicorp.com/terraform/install)  

* AWS CLI をインストールしていること  
  ➤ [AWS CLI インストール](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html)  

* IAM権限に関する認証設定が完了しておりリソースが作成できること  
  ➤ [IAM権限 認証設定](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-chap-authentication.html)  


## ■ 各種変数
[main.tf](./environment/main.tf) 内の `locals` にて変数設定しています、  
nodes変数がノード名称と台数の指定となるので必要に応じて値を変更してください。  

なおインスタンスタイプについて4GB以下だとKubernetesクラスター作成時にメモリ不足が発生したため、  
最小の`t3.medium`としています。


| 変数名                | デフォルト値                          | 説明           |
-----------------------|--------------------------------------|-----------------
| pj                   | container                            | プロジェクト名  |
| env                  | terraform                            | 環境名          |
| tags                 | pj = local.pj, env = local.env       | EC2タグ         |
| vpc_cidr             | 192.168.0.0/16                       | VPCのCIDR       |
| subnet_cidr          | 192.168.0.0/24                       | サブネットのCIDR |
| os_user              | ubuntu                               | Ansible実行用OSユーザー名 |
| nodes                | ["master-001", "master-002", "master-003", "worker-001", "worker-002"] | 作成するインスタンス名、およびホスト名 |
| instance_type        | t3.medium                            | インスタンスタイプ    |
| private_ssh_key_name | .ssh/ansible_key                     | Ansible用SSH鍵名 (秘密鍵)      |
| public_ssh_key_name  | .ssh/ansible_key.pub                 | Ansible用SSH鍵名 (公開鍵)      |
| key_pair_name        | key_pair_name                        | キーペア名           |
| current-ip           | chomp(data.http.ipv4_icanhazip.body) | SSH接続元IP (編集不要)   |
| allow_ssh_cidrs      | ${local.current-ip}/32               | SSH接続元IP (編集不要) |

## ■ 台数を変更したい場合
前述のnodes変数と合わせて以下のモジュールを修正してください。  
ノード名称は変数と同様の値にしてください。

### [local_file.tf](./module/local_file.tf) 
Ansible実行用のhostsファイル作成用の terraform です。
* 作成するノードを減らす場合は、`ip_address_XXXXX_XXX`の行を削除してください。  
* 作成するのノードを追加する場合は、`ip_address_XXXXX_XXX`の行を追加してください。  
  マスターノードは`master_XXX`、ワーカーノードは`worker_XXX`という名称にしてください。

```
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
```

### [ansible_inventory.tpl](./module/conf/ansible_inventory.tpl) 
Ansible実行用のhostsファイルを作成するテンプレートファイルです。  
* 作成するノードを減らす場合は、`hosts名`、`ansible_host`の行を削除してください。   
* 作成するのノードを追加する場合は、`hosts名`、`ansible_host`の行を追加してください。  
  マスターノードは`master_XXX`、ワーカーノードは`worker_XXX`という名称にしてください。

```
all:
  vars:
    ansible_user: "${user_name}"
    ansible_ssh_private_key_file: "${key_path}"
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
```

## ■ OSバージョンを変更したい場合
デフォルトだと `ubuntu23` の最新AMIを利用しています。  

変更したい場合は [ec2.tf](./module/ec2.tf) の `ami` の値を変更してください。  
他のOSバージョンについて同ファイル内のdataにて、`ubuntu18` `ubuntu20` `ubuntu22` の最新AMIを用意しています。

###  [ec2.tf](./module/ec2.tf) 
```
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
      "Name" = "${var.base_name}-${each.value}"
    },
    var.tags
  )

}
```

## ■ 構築手順
以降の手順は [environment](./environment) ディレクトリで実行してください。

(1) terraform init でディレクトリを初期化してください。
```
$ terraform init
```

(2) terraform apply でリソースを作成してください。
```
$ terraform apply
```

(3) Outputs: に出力された以下のコマンドで各インスタンスに接続できます。
```
ssh_command = {
  "container-master-001" = "ssh -i .ssh/ansible_key ubuntu@XXX.XXX.XXX.XXX"
  "container-master-002" = "ssh -i .ssh/ansible_key ubuntu@XXX.XXX.XXX.XXX"
  "container-master-003" = "ssh -i .ssh/ansible_key ubuntu@XXX.XXX.XXX.XXX"
  "container-worker-001" = "ssh -i .ssh/ansible_key ubuntu@XXX.XXX.XXX.XXX"
  "container-worker-002" = "ssh -i .ssh/ansible_key ubuntu@XXX.XXX.XXX.XXX"
}
```

(4) [ansible](../ansible/) ディレクトリへ移動してコンテナ実行環境の構築を進めてください。

(5) リソースが不要になったら `terraform destroy` でリソースを削除してください。
```
$ terraform destroy
```

## ■ 免責事項 
使用後は必ず `terraform destroy` を実行してください。  
複数のインスタンスを生成するため、消し忘れた場合には予想外の高額な料金が発生する可能性があります。

~~ちなみに作者は3敗ぐらいしています。~~

## ■ ライセンス
[Mozilla Public License v2.0](https://github.com/Lamaglama39/ansible-container-recipes/blob/main/LICENSE)
