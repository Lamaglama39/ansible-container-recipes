# ansible-container-recipes
`Docker swarm` および `Kubernetes` を実行する環境を設定するためのAnsible Playbookです。  

## ■ 動作環境
本リポジトリのプレイブックは、 `Ubuntu 18.04 ～ Ubuntu 23.04` にて動作確認をしております。  

その他Debian系のディストリビューションでも利用可能ではありますが、  
動作確認はしていないので各自でプレイブックの修正が必要になる可能性があります。

Ubuntuの各バージョンについては以下でダウンロードできます。  
* [Ubuntu ダウンロード](https://releases.ubuntu.com/?_gl=1*1n7jxlh*_gcl_au*MTkzOTIzMzI5Mi4xNzA3NTc1NzEx&_ga=2.130040527.1505846805.1709902322-508714518.1699449935)

## ■ 構築手順
実装する環境ごとに、以下の手順を実施してください。

### ・ オンプレ環境で実行する
[ansible](./ansible/) でプレイブックを実行してください。

### ・ クラウド環境で実行する
[terraform](./terraform) で環境構築したのち、  
[ansible](./ansible/) でプレイブックを実行してください。

## ■ ライセンス
[Mozilla Public License v2.0](https://github.com/Lamaglama39/ansible-container-recipes/blob/main/LICENSE)
