#! /bin/sh

source ./lib.sh
value_from_env
get_docker_info

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
  color_echo "Can't find connection from USER: ${1} now. (no problem)" yellow
fi




# telnetでコンテナ内のOpenVPN Managerに接続してrevoke対象を即時切断する
#echo -e -n "\n"
#cd ./docker_ovpn
## container名抽出
#DOCKER_CONTAINER_NAME=`docker-compose ps | grep -v Name | grep -v '\-\-\-' | awk '{print $1}'`
## containerのIPアドレスを抽出する
#DOCKER_CONTAINER_IP=`docker container inspect ${DOCKER_CONTAINER_NAME} | grep IPAddress | grep -Eo '([1-2]?[0-9]{0,2}\.){3,3}[1-2]?[0-9]{0,2}'`
#if [ $? -eq 0 ]; then
#  color_echo "Succeeded in getting Docker_container IP: ${DOCKER_CONTAINER_IP} NAME: ${DOCKER_CONTAINER_NAME}" yellow
#    else
#  color_echo "Failed in getting Docker_container IP & NAME"
#fi
#
#MANAGER_REV=`(sleep 3; echo "status"; sleep 1; echo "quit"; sleep 1) | telnet ${DOCKER_CONTAINER_IP} 7505`
#HIGE=`echo "${MANAGER_REV}" | grep -E ^${1},`
#color_echo "$`echo "${MANAGER_REV}" | grep -E ^${1},`" cyan
#
# telnetでの操作
#        (sleep 3; echo "kill ${1}" sleep3; echo quit; sleep 1) | telnet ${DOCKER_CONTAINER_IP} 7505
