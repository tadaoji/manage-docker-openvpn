# 概要
dockerとdocker-composeを利用し、OpenVPNを利用します。
このスクリプトでできることは以下の通りです。
* OpenVPN環境を構築する
* OpenVPNに繋ぐクライアントを作成する
* OpenVPNに登録されているクライアントを削除する
* OpenVPNに接続しているクライアントの通信を切る
* OpenVPN環境を削除する

# 必要な環境
* Linux
* Docker
* Docker-compose

# 初期設定
## 展開
任意のディレクトリにこのリポジトリを展開して下さい。
展開すると以下のようになります。
```
├── LICENSE
├── README.md
├── build_ovpn_instance.sh
├── client.conf.example
├── create_account.sh
├── delete_ovpn_instance.sh
├── disconnect_account.sh
├── docker_ovpn
│   ├── delete_compose.sh
│   ├── docker-compose.yml
│   └── docker_files
│       └── openvpn
│           ├── Dockerfile
│           └── run.sh
├── lib.sh
├── mount_dir
│   └── mnt_ovpn
│       ├── client.conf.example
│       └── server.conf.example
├── revoke_account.sh
└── set_docker_env.sh
```
docker_ovpnディレクトリにはdocker-composeおよびDockerfileなど、Dockerで使用するファイル群が入っています。
mount_dirはOpenVPNが利用する設定ファイル、各証明書ファイルなどが生成され入ります。

## 設定(.env)
.envが設定ファイルです。
基本的にこのスクリプトでは.envのみで設定を行います。
このファイルではコメントアウトには対応していません。

### DOCKER_OVPN_HOST_PORT
任意のPORT番号を入れて下さい。
OpenVPNのホストとクライアント間はこのPORTを利用することになります。
### DOCKER_OVPN_PROTOCOL_TYPE
OpenVPNのホストとクライアント間の通信プロトコルを決めます。
udpかtcpを設定して下さい。
### DOCKER_OVPN_DEVICE_TYPE
OpenVPNホストで用いるネットワークシステムを選ぶことができます
tap <- ブリッジ接続
tun <- ルーター
### DOCKER_OVPN_NET
OpenVPN内部で用いる仮想内部ネットワークを決めます。
### DOCKER_OVPN_SUBNET_MASK
DOCKER_OVPN_NETの内部ネットワークに対するサブネットマスクを指定します。
### DOCKER_OVPN_DNS_IP
DNS解決のためのサーバを選びます。
デフォルトではGoogle DNS(8.8.8.8)になっています。
### DOCKER_OVPN_CLIENT_TO_CLINET
接続されたクライアント同士をアクセス可能にするか決定します。
1 <- 許可
0 <- 拒否
### DOCKER_OVPN_HOST_NAME
ホストのドメイン名を指定して下さい。
### DOCKER_OVPN_DEST_HOST
ホストのグローバルIPアドレスを設定して下さい。
このIPアドレスがクライアントの接続先になります。
### DOCKER_OVPN_LOGS
OpenVPNのログを出力するか決定します。
1 <- 出力する
0 <- 出力しない
### EASYRSA_CRL_DAYS
証明書の有効期間を決めます。
単位は日数です。
デフォルトでは10年(3650)になっています。
### EASYRSA_CERT_EXPIRE
証明書廃棄リストの有効期限を決めます。
単位は日数です。
デフォルトでは10年(3650)になっています。
### DOCKER_OVPN_VIRTUAL_NET_NAME
Dockerで使用する仮想ネットワークの名前を決めます。
Dockerの使用に沿った任意の文字列が使えます。


## 使用方法
### OpenVPN環境を構築する
```bash
./build_ovpn_instance.sh
```
このスクリプトを実行すると、Docker containerが一つと、.envで指定された名前のnetworkが作られます。
```bash
docker network ls
NETWORK ID     NAME                  DRIVER    SCOPE

docker container ls
CONTAINER ID   IMAGE             COMMAND     CREATED          STATUS          PORTS                                         NAMES
0e00647e9a63   tadaoji/openvpn   "/run.sh"   18 seconds ago   Up 18 seconds   0.0.0.0:45493->1194/udp, :::45493->1194/udp   docker_ovpn_openvpn_
```
#### 作成されるファイル
./mount_dirの下に証明書などが作成されます。
.envの設定を反映したserver.confが作成されます。
もし設定ファイルを直接確認、編集したい場合、
./mount_dir/mnt_ovpn/server.conf
を確認して下さい。このファイルがOpenVPNで実際に動作しています。

#### Docker Containerを再起動した場合の動作
mount_dir以下にファイルが存在している場合、このスクリプトは既存の設定を利用します。
server.confを書き換えた場合、containerを再起動することで読み込まれます。

### クライアントを追加する
```bash
./create_account.sh <Client-Name>
```
\<Client-Name>は書き換えて下さい。
クライアントは複数追加することができます。
実行すると最後に以下の様な出力がされます。
このディレクトリにはクライアントが設定するために必要な以下のファイルが入っています。
* caファイル
* crtファイル
* keyファイル
* ta.keyファイル
* configファイル
このディレクトリをftpなどを使ってクライアントへダウンロードし、OpenVPNクライアントソフトへ設定して下さい。

server.confを手動で書き換えている場合、configファイルの設定は手動で書き換える必要があるかもしれません。

例
```
./create_account.sh exampleuser

(中略)
r/exampleuser_ta.key
Complete to create USER: exampleuser

------------------------------------------------
Generated files DIR -> /PATH/TO/DIR/manage-docker-openvpn/mount_dir/mnt_easy-rsa/clients/exampleuser
------------------------------------------------
```

### 接続中のクライアントを切断する
この切断は永続的なものではありません。
クライアントが再度接続をすると再開されます。
```bash
./disconnect_account.sh <Client-Name>
```

### 登録済みクライアントを削除する
接続中のクライアントは即時切断されます。
クライアントが接続を再開することは不可能になります。
```bash
./revoke_account.sh <Client-Name>
```

### OpenVPN環境を削除する
```bash
./delete_ovpn_instance.sh
```
使用されていたDocker ContainerおよびNetworkが削除されます。
このスクリプトを実行すると、途中で対話モードになり、設定ファイル、証明書ファイルを残すか聞かれます。
```
Do you wish to remove following directory and files?
./mount_dir/mnt_easy-rsa
./mount_dir/mnt_ovpn/logs
./mount_dir/mnt_ovpn/server.conf
yes/no
```
ここでnoにした場合、再開に必要なファイルが残ります。
yesにした場合、全ての設定ファイルは削除され、初期状態に戻ります。

# Credits
OpenVPN - [https://openvpn.net](https://openvpn.net)

