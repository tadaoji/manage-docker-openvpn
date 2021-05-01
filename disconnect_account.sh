#! /bin/bash

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
