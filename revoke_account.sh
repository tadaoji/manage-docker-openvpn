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
fi

## execしてcrl.pemの更新をする
echo -e "\n"
color_echo "---------- Re create crl.pem file ----------" magenta
docker container exec -w /opt/mnt_easy-rsa ${DOCKER_CONTAINER_NAME} /bin/sh -c "/usr/share/easy-rsa/easyrsa gen-crl"
if [ $? -eq 0 ]; then
  color_echo "Succeeded in re-creating crl.pem" yellow
else
  color_echo "Failed in re-creating crl.pem" red
fi

chmod o+r /docker/docker-files/ovpn/mount_dir/mnt_easy-rsa/pki/crl.pem
if [ $? -eq 0 ]; then
  color_echo "chmod o+r /docker/docker-files/ovpn/mount_dir/mnt_easy-rsa/pki/crl.pem .......Done" yellow
else
  color_echo "ERROR: chmod o+r /docker/docker-files/ovpn/mount_dir/mnt_easy-rsa/pki/crl.pem" red
fi

## execしてupdate-dbを行い廃棄リストを読み込ませる
#echo -e "\n"
#color_echo "---------- Reload easy-rsa DB ----------" magenta
#docker container exec -w /opt/mnt_easy-rsa ${DOCKER_CONTAINER_NAME} /bin/sh -c "echo 'yes' | /usr/share/easy-rsa/easyrsa update-db"
#if [ $? -eq 0 ]; then
#  color_echo "Succeeded in reload DB with /usr/share/easy-rsa/easyrsa update-db in docker ovpn container" yellow
#else
#  color_echo "Failed in reload DB with /usr/share/easy-rsa/easyrsa update-db in docker ovpn container" red
#fi


echo -e "\n"
# telnetでコンテナ内のOpenVPN Managerに接続してrevoke対象を即時切断する
# telnetでの操作
color_echo "---------- Start check ovpn connecting status ----------" magenta
MANAGER_RESPONSE=`(sleep 3; echo "status"; sleep 1; echo "quit"; sleep 1) | telnet ${DOCKER_CONTAINER_IP} 7505`
color_echo "`echo "${MANAGER_RESPONSE}" | grep -E ^${1},`" cyan
echo "${MANAGER_RESPONSE}" | grep -E ^${1}, 2>&1 1> /dev/null
if [ $? -eq 0 ]; then
  color_echo "Find connecting USER: ${1}" yellow
  echo -e "\n"
  color_echo "---------- kill connection from USER: ${1} ----------" magenta
  (sleep 3; echo "kill ${1}" sleep3; echo quit; sleep 1) | telnet ${DOCKER_CONTAINER_IP} 7505
  color_echo "Done" yellow
else
  color_echo "Can't find connection from USER: ${1} now. (no problem)" red
fi

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
  color_echo "Moved ${PATH_EASY_RSA}/clients/${1} to PATH_EASY_RSA/revoked_user/${1}" yellow
else
  color_echo "Failed in Moving ${PATH_EASY_RSA}/clients/${1} to PATH_EASY_RSA/revoked_user/${1}" red
fi

echo -e "\n"
color_echo "COMPLETE: DELETE USER: ${1}" cyan
