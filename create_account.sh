#! /bin/bash

source ./lib.sh

# 引数が入ってない場合はexit
if [ -z $1 ]; then
  color_echo "Need unique_account_name into argument 1" red
  exit 1
fi

# 既にユーザーディレクトリが作られていたらexit
if [ -d ./mount_dir/mnt_easy-rsa/clients/$1 ]; then
  color_echo "Already exists user: $1" red
  exit 1
fi

echo -e "\n"
color_echo "---------- Create client.conf ----------" magenta
# client.confの作成
EASYRSA_DIR=`readlink -f ./mount_dir/mnt_easy-rsa`
CLIENT_DIR=${EASYRSA_DIR}/clients/${1}
OVPN_DIR=`readlink -f ./mount_dir/mnt_ovpn`
CONFIG_PATH=${CLIENT_DIR}/${1}_client.conf

mkdir -p ${CLIENT_DIR}
if [ $? -eq 0 ]; then
  color_echo "Done mkdir -p ${CLIENT_DIR}" yellow
else
  color_echo "Failed mkdir -p ${CLIENT_DIR}" red
fi

cp ${OVPN_DIR}/client.conf.example ${CONFIG_PATH}
if [ $? -eq 0 ]; then
  color_echo "Succeeded in coping ${OVPN_DIR}/client.conf.example to ${CLIENT_DIR}/${1}_client.conf" yellow
else
  color_echo "Failed in coping ${OVPN_DIR}/client.conf.example to ${CLIENT_DIR}/${1}_client.conf" red
fi

# .envの情報を変数として取り込む
value_from_env  # ./lib.sh

echo -e "\n"
# client.confのプレースホルダーを環境変数で置換する
color_echo "---------- set each value in client.conf ----------" magenta
## DEVICE_TYPE
sed -i -e "s/__DEVICE_TYPE__/${DOCKER_OVPN_DEVICE_TYPE}/" ${CONFIG_PATH}
if [ $? -eq 0 ]; then
  color_echo "Succeeded in replacing __DEVICE_TYPE__ with ${DOCKER_OVPN_DEVICE_TYPE}" yellow
else
  color_echo "Failed in replacing __DEVICE_TYPE__ with ${DOCKER_OVPN_DEVICE_TYPE}" red
fi

## PROTOCOL_TYPE
sed -i -e "s/__PROTOCOL_TYPE__/${DOCKER_OVPN_PROTOCOL_TYPE}/" ${CONFIG_PATH}
if [ $? -eq 0 ]; then
  color_echo "Succeeded in replacing __PROTOCOL_TYPE__ with ${DOCKER_OVPN_PROTOCOL_TYPE}" yellow
else
  color_echo "Failed in replacing __PROTOCOL_TYPE__ with ${DOCKER_OVPN_PROTOCOL_TYPE}" red
fi

## DEST_VPN_SERVER
sed -i -e "s/__DEST_VPN_SERVER__/${DOCKER_OVPN_DEST_HOST}/" ${CONFIG_PATH}
if [ $? -eq 0 ]; then
  color_echo "Succeeded in replacing __DEST_VPN_SERVER__ with ${DOCKER_OVPN_DEST_HOST}" yellow
else
  color_echo "Failed in replacing __DEST_VPN_SERVER__ with ${DOCKER_OVPN_DEST_HOST}" red
fi

## PUBLIC_VPN_PORT
sed -i -e "s/__PUBLIC_VPN_PORT__/${DOCKER_OVPN_HOST_PORT}/" ${CONFIG_PATH}
if [ $? -eq 0 ]; then
  color_echo "Succeeded in replacing __PUBLIC_VPN_PORT__ with ${DOCKER_OVPN_HOST_PORT}" yellow
else
  color_echo "Failed in replacing __PUBLIC_VPN_PORT__ with ${DOCKER_OVPN_HOST_PORT}" red
fi

## CA_FILE_NAME
sed -i -e "s/__CA_FILE_NAME__/${1}_ca.crt/" ${CONFIG_PATH}
if [ $? -eq 0 ]; then
  color_echo "Succeeded in replacing __CA_FILE_NAME__ with ${1}_ca.crt" yellow
else
  color_echo "Failed in replacing __CA_FILE_NAME__ with ${1}_ca.crt" red
fi

## CERT_FILE_NAME
sed -i -e "s/__CERT_FILE_NAME__/${1}.crt/" ${CONFIG_PATH}
if [ $? -eq 0 ]; then
  color_echo "Succeeded in replacing __CERT_FILE_NAME__ with ${1}.crt" yellow
else
  color_echo "Failed in replacing __CERT_FILE_NAME__ with ${1}.crt" red
fi

## KEY_FILE_NAME
sed -i -e "s/__KEY_FILE_NAME__/${1}.key/" ${CONFIG_PATH}
if [ $? -eq 0 ]; then
  color_echo "Succeeded in replacing __KEY_FILE_NAME_ with ${1}.key" yellow
else
  color_echo "Failed in replacing __KEY_FILE_NAME_ with ${1}.key" red
fi 

## TA_FILE_NAME
sed -i -e "s/__TA_FILE_NAME__/${1}_ta.key/" ${CONFIG_PATH}
if [ $? -eq 0 ]; then
  color_echo "Succeeded in replacing __TA_FILE_NAME__ with ${1}_ta.key" yellow
else
  color_echo "Failed in replacing __TA_FILE_NAME__ with ${1}_ta.key" red
fi

echo -e "\n"
color_echo "---------- create account with easy-rsa in ovpn docker container ----------" magenta
# 各種証明書の作成
# docker-composeで使用する環境変数のセット
get_docker_info  # ./lib.sh
cd ./docker_ovpn
# docker container execを用いてclient証明書を作成する
docker container exec ${DOCKER_CONTAINER_NAME} /usr/share/easy-rsa/easyrsa build-client-full ${1} nopass
color_echo "docker container exec ${DOCKER_CONTAINER_NAME}  /usr/share/easy-rsa/easyrsa build-client-full ${1} nopass" cyan
if [ $? -eq 0 ]; then
  color_echo "Successed in generating client-key" yellow
else
  color_echo "Failed in generating client-key" red
  exit 1
fi

echo -e "\n"
color_echo "---------- copy each auth files to client_dir ----------" magenta
# クライアントに必要なファイルをコピーする
## ca.crt
cp ${EASYRSA_DIR}/pki/ca.crt ${CLIENT_DIR}/${1}_ca.crt
if [ $? -eq 0 ]; then
  color_echo "Copied ${EASYRSA_DIR}/pki/ca.crt to ${CLIENT_DIR}/${1}_ca.crt" yellow
else
  color_echo "ERROR: Copied ${EASYRSA_DIR}/pki/ca.crt to ${CLIENT_DIR}/${1}_ca.crt" red
fi

## client.crt
cp ${EASYRSA_DIR}/pki/issued/${1}.crt ${CLIENT_DIR}/${1}.crt
if [ $? -eq 0 ]; then
  color_echo "Copied ${EASYRSA_DIR}/pki/issued/${1}.crt to ${CLIENT_DIR}/${1}.crt" yellow
else
  color_echo "ERROR: Copied ${EASYRSA_DIR}/pki/issued/${1}.crt to ${CLIENT_DIR}/${1}.crt" red
fi

## client.key
cp ${EASYRSA_DIR}/pki/private/${1}.key ${CLIENT_DIR}/${1}.key
if [ $? -eq 0 ]; then
  color_echo "Copied ${EASYRSA_DIR}/pki/private/${1}.key to ${CLIENT_DIR}/${1}.key" yellow
else
  color_echo "ERROR: Copied ${EASYRSA_DIR}/pki/private/${1}.key to ${CLIENT_DIR}/${1}.key" red
fi

## ta.key
cp ${EASYRSA_DIR}/pki/ta.key ${CLIENT_DIR}/${1}_ta.key
if [ $? -eq 0 ]; then
  color_echo "Copied ${EASYRSA_DIR}/pki/ta.key to ${CLIENT_DIR}/${1}_ta.key" yellow
else
  color_echo "ERROR: Copied ${EASYRSA_DIR}/pki/ta.key to ${CLIENT_DIR}/${1}_ta.key" red
fi

if [ $? -eq 0 ]; then
  color_echo "Complete to create USER: $1" yellow
else
  color_echo "Failed to create USER: $1" red
fi

# 作成したClientディレクトリのPATHを表示
echo -n -e "\n"
cd ${CLIENT_DIR}
echo -n -e "\n"
color_echo "------------------------------------------------" yellow
color_echo "Generated files DIR -> `pwd`" cyan
color_echo "------------------------------------------------" yellow
echo -n -e "\n"
