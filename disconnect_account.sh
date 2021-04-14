#! /bin/sh
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
# telnetでコンテナ内のOpenVPN Managerに接続してrevoke対象を即時切断する
echo -e -n "\n"
cd ./docker_ovpn
# container名抽出
DOCKER_CONTAINER_NAME=`docker-compose ps | grep -v Name | grep -v '\-\-\-' | awk '{print $1}'`
# containerのIPアドレスを抽出する
DOCKER_CONTAINER_IP=`docker container inspect ${DOCKER_CONTAINER_NAME} | grep IPAddress | grep -Eo '([1-2]?[0-9]{0,2}\.){3,3}[1-2]?[0-9]{0,2}'`
if [ $? -eq 0 ]; then
  color_echo "Succeeded in getting Docker_container IP: ${DOCKER_CONTAINER_IP} NAME: ${DOCKER_CONTAINER_NAME}" yellow
    else
  color_echo "Failed in getting Docker_container IP & NAME"
fi

MANAGER_REV=`(sleep 3; echo "status"; sleep 1; echo "quit"; sleep 1) | telnet ${DOCKER_CONTAINER_IP} 7505`
HIGE=`echo "${MANAGER_REV}" | grep -E ^${1},`
color_echo "$`echo "${MANAGER_REV}" | grep -E ^${1},`" cyan

# telnetでの操作
#        (sleep 3; echo "kill ${1}" sleep3; echo quit; sleep 1) | telnet ${DOCKER_CONTAINER_IP} 7505
