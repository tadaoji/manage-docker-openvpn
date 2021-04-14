#!/bin/sh

function color_echo() {
  local ESC
  ESC=$(printf '\033')
  local color

  if [ -z $2 ]; then
    echo $1
    exit 1
  fi

  if [ $2 = black ]; then
    color=30m
  elif [ $2 = red ]; then
    color=31m
  elif [ $2 = green ]; then
    color=32m
  elif [ $2 = yellow ]; then
    color=33m
  elif [ $2 = blue ]; then
    color=34m
  elif [ $2 = magenta ]; then
    color=35m
  elif [ $2 = cyan ]; then
    color=36m
  elif [ $2 = white ]; then
    color=37m
  else
    color=0
  fi

  if [ $color = 0 ]; then
    echo $1
  else
    echo "${ESC}[${color}${1}${ESC}[m"
  fi
}

mask2cidr ()
{
  # Assumes there's no "255." after a non-255 byte in the mask
  local x=${1##*255.}
  set -- 0^^^128^192^224^240^248^252^254^ $(( (${#1} - ${#x})*2 )) ${x%%.*}
  x=${1%%$3*}
  echo $(( $2 + (${#x}/4) ))
}

color_echo "Start checking .env" magenta
# check .env
env_flag=0
if [ -z ${DOCKER_OVPN_HOST_PORT} ]; then
  color_echo "ERROR ENV \"DOCKER_OVPN_HOST_PORT\" is not exist on .env" red
  env_flag=1
fi

if [ -z ${DOCKER_OVPN_PROTOCOL_TYPE} ]; then
  color_echo "ERROR ENV \"DOCKER_OVPN_PROTOCOL_TYPE\" is not exist on .env" red
  env_flag=1
fi

if [ -z ${DOCKER_OVPN_DEVICE_TYPE} ]; then
  color_echo "ERROR ENV \"DOCKER_OVPN_DEVICE_TYPE\" is not exist on .env" red
  env_flag=1
fi

if [ -z ${DOCKER_OVPN_NET} ]; then
  color_echo "ERROR ENV \"DOCKER_OVPN_NET\" is not exist on .env" red
  env_flag=1
fi

if [ -z ${DOCKER_OVPN_SUBNET_MASK} ]; then
  color_echo "ERROR ENV \"DOCKER_OVPN_SUBNET_MASK\" is not exist on .env" red
  env_flag=1
fi

if [ -z ${DOCKER_OVPN_DNS_IP} ]; then
color_echo "ERROR ENV \"DOCKER_OVPN_DNS_IP\" is not exist on .env" red
env_flag=1
fi

if [ -z ${DOCKER_OVPN_CLIENT_TO_CLINET} ]; then
  color_echo "ERROR ENV \"DOCKER_OVPN_CLIENT_TO_CLINET\" is not exist on .env" red
  env_flag=1
fi

if [ -z ${DOCKER_OVPN_HOST_NAME} ]; then
  color_echo "ERROR ENV \"DOCKER_OVPN_HOST_NAME\" is not exist on .env" red
  env_flag=1
fi

if [ -z ${DOCKER_OVPN_LOGS} ]; then
  color_echo "ERROR ENV \"DOCKER_OVPN_LOGS\" is not exist on .env" red
  env_flag=1
fi

if [ -z ${EASYRSA_CRL_DAYS} ]; then
  color_echo "ERROR ENV \"EASYRSA_CRL_DAYS\" is not exist on .env" red
  env_flag=1
fi

if [ -z ${EASYRSA_CERT_EXPIRE} ]; then
  color_echo "ERROR ENV \"EASYRSA_CERT_EXPIRE\" is not exist on .env" red
  env_flag=1
fi

if [ $env_flag -eq 1 ]; then
  color_echo "You should check .env configures" red
else
  color_echo "No problem .env" yellow
fi
echo -e "\n"

# logsがmnt_ovpn以下になければ作成する
if [ -d /opt/mnt_ovpn/logs ]; then
  color_echo "Already exists /opt/mnt_ovpn/logs" yellow
else
  mkdir /opt/mnt_ovpn/logs
  color_echo "Created /opt/mnt_ovpn/logs" yellow
fi
echo -e "\n"

# server.conf書き換え
color_echo "Start change server.conf" magenta
SERVER_CONF_PATH=/opt/mnt_ovpn/server.conf
STATUS_LOG_PATH="status \/opt\/mnt_ovpn\/logs\/openvpn-status.log"
OVPN_LOG_PATH="log-append \/opt\/mnt_ovpn\/logs\/openvpn.log"

if [ -f ${SERVER_CONF_PATH} ]; then
  color_echo "Already exists server.conf" red
  color_echo "Delete server.conf, if you want automaticaly configuration." red
else
  cp ${SERVER_CONF_PATH}.example ${SERVER_CONF_PATH}
  
  if [ $? -eq 0 ]; then
    color_echo "copy server.conf.example to server.conf" yellow
  else
    color_echo "Failed to copy server.conf.example to server.conf" red
    exit 1
  fi
  # 環境変数の値でserver.confを書き換え
  # DOCKER_OVPN_PROTOCOL_TYPE -> s/__PROTOCOL_TYPE__/
  sed -i -e "s/__PROTOCOL_TYPE__/${DOCKER_OVPN_PROTOCOL_TYPE}/" ${SERVER_CONF_PATH}
  echo "s/__PROTOCOL_TYPE__/${DOCKER_OVPN_PROTOCOL_TYPE}/" ${SERVER_CONF_PATH}
  if [ $? -eq 0 ]; then
    color_echo "Success to set proto ${DOCKER_OVPN_PROTOCOL_TYPE}" yellow
  else
    color_echo "You should check the value DOCKER_OVPN_PROTOCOL_TYPE" red
  fi
  # DOCKER_OVPN_DEVICE_TYPE -> __DEVICE_TYPE__
  sed -i -e "s/__DEVICE_TYPE__/${DOCKER_OVPN_DEVICE_TYPE}/" ${SERVER_CONF_PATH}
  if [ $? -eq 0 ]; then
    color_echo "Success to set dev ${DOCKER_OVPN_DEVICE_TYPE}" yellow
  else
    color_echo "You should check the value DOCKER_OVPN_DEVICE_TYPE on .env" red
  fi
  
  # DOCKER_OVPN_NET, DOCKER_OVPN_SUBNET_MASK -> sever __DOCKER_OVPN_NET__ __VPN_SUBNET_MASK__
  sed -i -e "s/__DOCKER_OVPN_NET__/${DOCKER_OVPN_NET}/" ${SERVER_CONF_PATH}
  sed -i -e "s/__VPN_SUBNET_MASK__/${DOCKER_OVPN_SUBNET_MASK}/" ${SERVER_CONF_PATH}
  if [ $? -eq 0 ]; then
    color_echo "Success to set \"server ${DOCKER_OVPN_NET} ${DOCKER_OVPN_SUBNET_MASK}\"" yellow
  else
    color_echo "You should check values \"DOCKER_OVPN_NET\" and \"DOCKER_OVPN_SUBNET_MASK\"" red
  fi

  # DOCKER_OVPN_DNS_IP -> s/__DNS_IP__
  sed -i -e  "s/__DNS_IP__/${DOCKER_OVPN_DNS_IP}/" ${SERVER_CONF_PATH}
  if [ $? -eq 0 ]; then
    color_echo "Success to set \"push \"dhcp-option DNS ${DOCKER_OVPN_DNS_IP}\"\"" yellow
  else
    color_echo "You should check the value \"DOCKER_OVPN_DNS_IP\"" red
  fi

  # DOCKER_OVPN_CLIENT_TO_CLINET -> __CLIENT_TO_CLIENT__
  client_to_client=""
  if [ ${DOCKER_OVPN_CLIENT_TO_CLINET} -eq 1 ]; then
    client_to_client=client-to-client
  fi

  sed -i -e "s/__CLIENT_TO_CLIENT__/${client_to_client}/" ${SERVER_CONF_PATH}
  if [ $? -eq 0 ]; then
    color_echo "Success to set \"client-to-client or blank.\"" yellow
  else
    color_echo "You should check the value \"DOCKER_OVPN_CLIENT_TO_CLINET\"" red
  fi
  
  # LOGS config
  if [ ${DOCKER_OVPN_LOGS} -eq 1 ]; then
    sed -i -e "s/__STATUS_LOG__/${STATUS_LOG_PATH}/" ${SERVER_CONF_PATH}
    sed -i -e "s/__OVPN_LOG__/${OVPN_LOG_PATH}/" ${SERVER_CONF_PATH}
  elif [ ${DOCKER_OVPN_LOGS} -eq 0 ]; then # envにDOCKER_OVPN_LOGSが0であればログ出力をしないように行を削除
    sed -i -e "s/__STATUS_LOG__/d" ${SERVER_CONF_PATH}
    sed -i -e "s/__OVPN_LOG__/d" ${SERVER_CONF_PATH}
  else
    sed -i -e "s/__STATUS_LOG__/d" ${SERVER_CONF_PATH}
    sed -i -e "s/__OVPN_LOG__/d" ${SERVER_CONF_PATH}
    color_echo "Error DOCKER_OVPN_LOGS incorrect value" red
    color_echo "Disable LOGS" red
  fi
fi
echo -e "\n"

############## nat ###############
color_echo "add iptables nat masquerade" magenta
OVPN_CIDR=$(mask2cidr ${DOCKER_OVPN_SUBNET_MASK})

# MASQUERADE設定作成
OUTPUT_DEVICE=$(ip r | grep default | awk 'match($0, /\<dev/) {print substr($0, RSTART)}' | awk {'print $2'})
if [ -z "${OUTPUT_DEVICE}" ]; then
  color_echo "ERROR: couldn't get OUTPUT_DEVICE" red

else
  iptables -t nat -C POSTROUTING -s ${DOCKER_OVPN_NET}/${OVPN_CIDR} -o ${OUTPUT_DEVICE} -j MASQUERADE || {
    iptables -t nat -A POSTROUTING -s ${DOCKER_OVPN_NET}/${OVPN_CIDR} -o ${OUTPUT_DEVICE} -j MASQUERADE
}
fi

if [ $? -eq 0 ]; then
  color_echo "ADD new NAT MASQUERADE table" yellow
  color_echo "Done -> \"iptables -t nat -A POSTROUTING -s ${DOCKER_OVPN_NET}/${OVPN_CIDR} -o ${OUTPUT_DEVICE} -j MASQUERADE\"" yellow
else
  color_echo "Error add new iptables nat table." red
  color_echo "\"iptables -t nat -A POSTROUTING -s ${DOCKER_OVPN_NET}/${OVPN_CIDR} -o ${OUTPUT_DEVICE} -j MASQUERADE\"" red
fi

# MASQUERADE設定作成

# natデバイス作成
if [ ! -d /dev/net ]; then
  mkdir -p /dev/net
  color_echo "new created /dev/net/" yellow
fi

if [ ! -c /dev/net/tun ]; then
  mknod /dev/net/tun c 10 200
  color_echo "new created /dev/net/tun" yellow
fi
echo -e "\n"
# easy-rsa
color_echo "################ easy-rsa ################" magenta
cd /opt/mnt_easy-rsa/

if [ ! -d "/opt/mnt_easy-rsa/pki" ]; then
  color_echo "not exist /opt/mnt_easy-rsa/pki" yellow
  color_echo "new create easy-rsa files" yellow
  
  # init-pki
  color_echo "################ init-pki ################" magenta
  /usr/share/easy-rsa/easyrsa init-pki
  echo "${DOCKER_OVPN_HOST_NAME}" |/usr/share/easy-rsa/easyrsa build-ca nopass
  if [ $? -eq 0 ]; then
    color_echo "Success to create /opt/mnt_easy-rsa/pki/ca.crt no-pass" yellow
  else
    color_echo "Failed to create /opt/mnt_easy-rsa/pki/ca.crt no-pass" red
  fi
  echo -e "\n"
  # build-server-full
  color_echo "################ build-server-full ################" magenta
  /usr/share/easy-rsa/easyrsa  build-server-full server nopass
  if [ $? -eq 0 ]; then
    color_echo "Success to generate server key" yellow
  else
    color_echo "Failed to generate server key" red
  fi
  echo -e "\n"
  
  # ta.key
  color_echo "################ ta.key ################" magenta
  /usr/sbin/openvpn --genkey --secret pki/ta.key
  if [ $? -eq 0 ]; then
    color_echo "Success to generate ta.key" yellow
  else
    color_echo "Failed to genrate ta.key" red
  fi
  echo -e "\n"

  # gen-dh
  color_echo "################ gen-dh ################" magenta
  /usr/share/easy-rsa/easyrsa gen-dh
  if [ $? -eq 0 ]; then
    color_echo "Success to create /opt/mnt_easy-rsa/pki/dh.pem" yellow
  else
    color_echo "Failed to create /opt/mnt_easy-rsa/pki/dh.pem" red
  fi
  echo -e "\n"

  # ################ revoke cert list ################
  color_echo "################ revoke cert list ################" magenta
  color_echo "################ generate dmy client ################" magenta
  echo "easy-rsa/pki/private/ca.key" | /usr/share/easy-rsa/easyrsa build-client-full dmy nopass
  if [ $? -eq 0 ]; then
    color_echo "Success to create dmy client key" yellow
  else
    color_echo "Failed to create dmy client key" red
  fi
  echo -e "\n"
  
  color_echo "################ revoke dmy ################" magenta
  echo "yes" | /usr/share/easy-rsa/easyrsa revoke dmy
  echo -e "\n"

  color_echo "################ gen-crl ################" magenta
  /usr/share/easy-rsa/easyrsa gen-crl

else
  color_echo "Already exist \"/opt/mnt_easy-rsa/pki\"" yellow
fi

color_echo "START OPENVPN SERVICE" yellow
/usr/sbin/openvpn --config /opt/mnt_ovpn/server.conf

