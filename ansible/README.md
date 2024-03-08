# ansible
コンテナオーケストレーション環境を実装するための ansible です。  
`Docker Swarm` と `kubernetes` を用意しているので、お好きな方を選んでください。  

なおパッケージやネットワークセグメントが競合しないように設定しているので両方導入することもできますが、  
実験目的以外では基本的に非推奨です。

## ■ 前提条件
Ansible 実行にあたり以下が前提条件となります。  
未導入の場合は記載の公式ドキュメントを参考に設定してください。

* Ansible をインストールしていること  
  ➤ [Ansible インストール](https://docs.ansible.com/ansible/2.9_ja/installation_guide/intro_installation.html)  

* Ansible実行対象へSSH接続が可能なこと  
  ➤ [Ansible SSH設定](https://docs.ansible.com/ansible/2.9_ja/user_guide/connection_details.html)  


## ■ 利用するSSH鍵
構築する環境ごとに以下のSSH鍵を利用してください。

### - オンプレ環境
各サーバのSSH接続で利用しているSSH鍵を用意してください。

### - クラウド環境
[Terraform](../terraform/environment/main.tf) 実行時に作成された [.ssh](.ssh/) ディレクトリに格納されているSSH鍵を利用してください。

## ■ インベントリ
Absible実行先のサーバを記載しているリストです。  
構築する環境ごとに以下の通りファイルを修正してください。

### - オンプレ環境
[hosts.yml](./hosts/hosts.yml) を実際の環境に合わせて以下の項目の設定値を修正してください。

#### (1) 認証情報
Ansible実行先のOSユーザーに関する設定です。  
なおplaybook実行時の引数で認証情報を指定することもできるので、  
その場合は以下をご参照ください。  
* [Ansible SSH設定](https://docs.ansible.com/ansible/2.9_ja/user_guide/connection_details.html)

| 変数名                        | 説明                                                   |
-------------------------------|--------------------------------------------------------|
| ansible_user                 | Ansible実行先で利用するOSユーザーです。sudo権限が必要です。 |
| ansible_ssh_private_key_file | 上記OSユーザーに接続するためのSSH鍵です。     |
| ansible_become_pass          | 上記OSユーザーに接続するためのパスワードです。 |


#### (2) ノード設定
Ansible実行先のノードに関する設定です。
ホスト名/IPアドレスを任意の値に設定してください。
なお `master_leader` はクラスター作成を実行するので、増減は不可となります。
`master_other` と `worker` については必要に応じて増減してください。

| グループ名     | ホスト名     | 説明                                               |
----------------|-------------|----------------------------------------------------|
| master_leader | master-001  | クラスター作成を実行するマスターノード、台数の増減不可  |
| master_other  | master-XXX  | 冗長化構成のためのマスターノード、台数の増減可         |
| worker        | worker-XXX  | ワーカーノード、台数の増減可                         |

#### インベントリ 設定例
```
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ./.ssh/ssh_key.pem
    ansible_become_pass: ubuntu_password
  children:
    master_leader:
      hosts:
        master-001:
          ansible_host: 192.168.0.100
    master_other:
      hosts:
        master-002:
          ansible_host: 192.168.0.110
        master-003:
          ansible_host: 192.168.0.111
    worker:
      hosts:
        worker-001:
          ansible_host: 192.168.0.120
        worker-002:
          ansible_host: 192.168.0.121
```

### - クラウド環境
[Terraform](../terraform/environment/main.tf) 実行時に作成されたインベントリをそのまま利用可能なので、ファイルの修正は編集不要です。  
ファイル名は [ansible_inventory.yml](./hosts/ansible_inventory.yml) です。

## ■ プレイブック
各プレイブックの概要と設定値について解説します。

### Docker Swarm

---
* [01-docker-install.yml](./docker-setting/01-docker-install.yml)
  - Docker 関連のパッケージをインストールします。  
    実行完了した段階で Docker を利用できます。

---
* [02-docker-swarm-create.yml](./docker-setting/02-docker-swarm-create.yml)
  - Swarmクラスターを作成します。
  - `pod_network_cidr`変数 はポッドで利用するIPアドレスプールの設定です。  
    既存のアドレス範囲と重複しない値を設定してください。
```
  vars:
    pod_network_cidr: "10.0.0.0/16"
```

---
* [03-docker-swarm-join.yml](./docker-setting/03-docker-swarm-join.yml)
  - 他のマスターノード、ワーカーノードをSwarmクラスターに参加させます。
  - マスターノードについてはDrain設定しています。
  - `pod_network_cidr`変数 はポッドで利用するIPアドレスプールの設定です。  
    [02-docker-swarm-create.yml](./docker-setting/02-docker-swarm-create.yml) で設定した値と同様の値を設定してください。
```
  vars:
    pod_network_cidr: "10.0.0.0/16"
```

---
* [04-docker-swarm-reset.yml](./docker-setting/04-docker-swarm-reset.yml)
  - Swarmクラスターをリセットします。  
    再度Swarmクラスターを作成する場合は、[02-docker-swarm-create.yml](./docker-setting/02-docker-swarm-create.yml ) から再実行してください。


### Kubernetes

---
* [01-kubernetes-install.yml](./kubernetes-setting/01-kubernetes-install.yml)
  - Kubernetes関連パッケージのインストール、およびOSレベルの各種初期設定を実施します。
  - Kubernetes のバージョンは `kubernetes`変数 で指定しています。  
    現在の最新バージョンについては以下で確認できます。  
    [Kubernetes Github](https://github.com/kubernetes/kubernetes)
```
  vars:
    kubernetes_version: "v1.29"
```

---
* [02-kubernetes-create-cluster.yml](./kubernetes-setting/02-kubernetes-create-cluster.yml)
  - Kubernetesクラスターを作成します。
  - `pod_network_cidr`変数 はポッドで利用するIPアドレスプールの設定です。  
    既存のアドレス範囲と重複しない値を設定してください。
```
  vars:
    pod_network_cidr: "10.1.0.0/16"
```

---
* [03-kubernetes-create-network.yml](./kubernetes-setting/03-kubernetes-create-network.yml)
  - calicoでCRIの設定を実施します。
  - `pod_network_cidr`変数 はポッドで利用するIPアドレスプールの設定です。  
    [02-kubernetes-create-cluster.yml](./kubernetes-setting/02-kubernetes-create-cluster.yml) で設定した値と同様の値を設定してください。
```
  vars:
    pod_network_cidr: "10.1.0.0/16"
```

---
* [04-kubernetes-join.yml](./kubernetes-setting/04-kubernetes-join.yml)
  - 他のマスターノード、ワーカーノードをKubernetesクラスターに参加させます。
  - マスターノードについてはDrain設定しています。

---
* [05-kubernetes-reset.yml](./kubernetes-setting/05-kubernetes-reset.yml)
  - Kubernetesクラスターをリセットします。  
    再度Kubernetesクラスターを作成する場合は、[02-kubernetes-create-cluster.yml](./kubernetes-setting/02-kubernetes-create-cluster.yml ) から再実行してください。

## ■ 構築手順
以降の手順は [ansible](../ansible/) ディレクトリで実行してください。

(1) 以下のようなコマンド形式で前述のプレイブックの項番順に実施してください。

#### ・ コマンド形式
```
$ ansible-playbook -i ${インベントリ} ${プレイブック}
```
#### ・ 実行例
```
$ ansible-playbook -i hosts/hosts.yml docker-setting/01-docker-install.yml
```

(2) 以下のオプションでプレイブック実行時に認証情報を指定することもできます。  
    インベントリにて認証情報を記載していない場合は、こちらのオプションを指定してください。

* `--ask-pass  `  
  OSユーザーログイン用のパスワード

* `--ask-become-pass`  
  特権昇格(sudo)用のパスワード

* `--private-key`  
  OSユーザーログイン用のSSH認証鍵

#### ・ コマンド形式
```
$ ansible-playbook -i ${インベントリ} ${プレイブック} \
  --ask-pass \
  --ask-become-pass \
  --private-key .ssh/ssh_key.pem
```
#### ・ 実行例
```
$ ansible-playbook -i hosts/hosts.yml docker-setting/01-docker-install.yml \
  --ask-pass \
  --ask-become-pass \
  --private-key .ssh/ssh_key.pem
```

## ■ 免責事項 
各プレイブックについて最低限の冪等性は確保しているため複数回実行しても問題が起きないようにしていますが、  
実運用/本番運用にて使用する際には、十分なテストと検証を経て適合性を確認してください。  

本プレイブックを実運用/本番運用に適用する場合、利用者自身の責任で行う必要があります。  
作者は、本プレイブックの使用によって発生した直接的、間接的な損害に対して一切の責任を負いません。  

## ■ ライセンス
[Mozilla Public License v2.0](https://github.com/Lamaglama39/ansible-container-recipes/blob/main/LICENSE)
