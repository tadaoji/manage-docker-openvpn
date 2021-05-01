#! /bin/bash

source ./lib.sh

# docker-composeで使用する環境変数のセット
export `grep DOCKER_OVPN_HOST_PORT .env`

cd docker_ovpn  # cd
docker-compose ps | awk '{print $3}' | grep "Up" 2>&1 1> /dev/null
if [ ! $? -eq 0 ]; then
  color_echo "Can't find docker-compose container" red
fi

# docker-compose ps でコンテナが確認できるかチェックする
if [ `docker-compose ps | wc -l` -gt 2 ]; then
  color_echo "Find docker-compose container" yellow
  docker-compose ps
  echo -e -n "\n"

    # docker-compose down をする
    docker-compose down --volumes --remove-orphans
    if [ ! $? -eq 0 ]; then
      color_echo "Error, Can't remove docker-compose container" red
      exit 1
    fi
    
    echo -e -n "\n"
    
    # docker-compose ps の結果をチェックしてコンテナが消えたか見る
    if [ `docker-compose ps | wc -l` -eq 2 ]; then
      color_echo "docker-compose down .....Done" yellow
      docker-compose ps
    else
      color_echo "Error, docker-compose down" red
    fi
    
else
  color_echo "Not find docker-compose container" red
  docker-compose ps
fi

echo -e -n "\n"

# 対話式で削除についてユーザーに確認する
function ConfirmExecution() {
  color_echo "Do you wish to remove following directory and files?" cyan
  color_echo "./mount_dir/mnt_easy-rsa" cyan
  color_echo "./mount_dir/mnt_ovpn/logs" cyan
  color_echo "./mount_dir/mnt_ovpn/server.conf" cyan
  color_echo "yes/no" cyan
  
  read input

  if [ "${input}" = 'yes' ]; then
    echo "excute"
  elif [ -z ${input} ]; then
    echo "Abort"
    exit 1
  else
    echo "Abort"
    exit 1
  fi
}

ConfirmExecution

echo -e "\n"

cd ../  # cd ovpn
# ./mount_dir/mnt_easy-rsa の削除
if [ -d ./mount_dir/mnt_easy-rsa ]; then  # 対象が存在するかチェック
  color_echo "remove ./mount_dir/mnt_easy-rsa" yellow
  rm -rf ./mount_dir/mnt_easy-rsa
  if [ $? -eq 0 ]; then
    color_echo "Done" yellow
  else
    color_echo "Error, Can't remove ./mount_dir/mnt_easy-rsa" red  # なんらかの問題で消せなかった場合
    exit 1
  fi
else
  color_echo "Already nothing ./mount_dir/mnt_easy-rsa" red  # 対象が既にない場合
fi
echo -e -n "\n"

# ./mount_dir/mnt_ovpn/logs の削除
if [ -d ./mount_dir/mnt_ovpn/logs ]; then
  color_echo "remove ./mount_dir/mnt_ovpn/logs" yellow
  rm -rf ./mount_dir/mnt_ovpn/logs
  if [ $? -eq 0 ]; then
    color_echo "Done" yellow
  else
    color_echo "Error, Can't remove ./mount_dir/mnt_ovpn/logs" red
    exit 1
  fi
else
  color_echo "Already nothing ./mount_dir/mnt_ovpn/logs" red
fi
echo -e -n "\n"

# ./mount_dir/mnt_ovpn/server.conf の削除
if [ -f ./mount_dir/mnt_ovpn/server.conf ]; then
  color_echo "remove ./mount_dir/mnt_ovpn/server.conf" yellow
  rm -rf ./mount_dir/mnt_ovpn/server.conf
  if [ $? -eq 0 ]; then
    color_echo "Done" yellow
  else
    color_echo "Error, Can't remove ./mount_dir/mnt_ovpn/server.conf" red
    exit 1
  fi
else
  color_echo "Already nothing ./mount_dir/mnt_ovpn/server.conf" red
fi
