#! /bin/sh

source ./lib.sh

# 引数が入ってない場合はexit
if [ -z $1 ]; then
  color_echo "Need account_name into argument 1" red
  exit 1
fi

# revoke対象のアカウントディレクトリが存在するか確認する
if [ ! -d ./mount_dir/mnt_easy-rsa/clients/${1} ]; then
  color_echo "Revoke_user is not exists." red
  exit 1
fi

# ovpn managerにdocker execにより接続する準備
# .envの情報を変数として取り込む
value_from_env # ./lib.sh

# docker ovpnのコンテナ名、IPなど情報収集
get_docker_info  # ./lib.sh

echo -e "\n"
color_echo "---------- Revoke account with easy-rsa in ovpn docker container ----------" magenta
# execしてrevokeする
docker container exec -w /opt/mnt_easy-rsa ${DOCKER_CONTAINER_NAME} /bin/sh -c "echo 'yes' | /usr/share/easy-rsa/easyrsa revoke ${1}"
if [ $? -eq 0 ]; then
  color_echo "Succeeded in delete client: ${1}  with easy-rsa" yellow
else
  color_echo "Failed in delete client: ${1}  with easy-rsa" red
  exit 1
fi

## execしてcrl.pemの更新をする
echo -e "\n"
color_echo "---------- Re create crl.pem file ----------" magenta
docker container exec -w /opt/mnt_easy-rsa ${DOCKER_CONTAINER_NAME} /bin/sh -c "/usr/share/easy-rsa/easyrsa gen-crl"
if [ $? -eq 0 ]; then
  color_echo "Succeeded in re-creating crl.pem" yellow
else
  color_echo "Failed in re-creating crl.pem" red
  exit 1
fi

chmod o+r ./mount_dir/mnt_easy-rsa/pki/crl.pem
if [ $? -eq 0 ]; then
  color_echo "chmod o+r ./mount_dir/mnt_easy-rsa/pki/crl.pem .......Done" yellow
else
  color_echo "ERROR: chmod o+r ./mount_dir/mnt_easy-rsa/pki/crl.pem" red
  exit 1
fi

# telnetでコンテナ内のOpenVPN Managerに接続してrevoke対象を即時切断する
./disconnect_account.sh

# revokeしたclient DIRを削除（mnt_eay-rsa/revoked_user/以下に移動）する
## revoked_userが存在するかチェックする
echo -e "\n"
color_echo "---------- Remove client DIR ----------" magenta
PATH_EASY_RSA=`readlink -f ./mount_dir/mnt_easy-rsa`
if [ ! -d ${PATH_EASY_RSA}/revoked_user ]; then
  mkdir -p ${PATH_EASY_RSA}/revoked_user
  color_echo "Created ${PATH_EASY_RSA}/revoked_user" yellow
fi

mv ${PATH_EASY_RSA}/clients/${1} ${PATH_EASY_RSA}/revoked_user/`date '+%Y%m%d-%H%M'`-${1}
if [ $? -eq 0 ]; then
  color_echo "Moved ${PATH_EASY_RSA}/clients/${1} to ${PATH_EASY_RSA}/revoked_user/${1}" yellow
else
  color_echo "Failed in Moving ${PATH_EASY_RSA}/clients/${1} to PATH_EASY_RSA/revoked_user/${1}" red
fi

echo -e "\n"
color_echo "COMPLETE: DELETE USER: ${1}" cyan
