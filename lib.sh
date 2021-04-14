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

function get_docker_info() {
  # docker-composeで使用する環境変数のセット
  export `grep DOCKER_OVPN_HOST_PORT .env`
  cd ./docker_ovpn
  # container名抽出
  DOCKER_CONTAINER_NAME=`docker-compose ps | grep -v Name | grep -v '\-\-\-' | awk '{print $1}'`
  if [ $? -eq 0 ]; then
    color_echo "Docker container name has been gotten." yellow
  else
    color_echo "Failed in getting Docker container name" red
    exit 1
   fi

  # containerのIPアドレスを抽出する
  DOCKER_CONTAINER_IP=`docker container inspect ${DOCKER_CONTAINER_NAME} | grep IPAddress | grep -Eo '([1-2]?[0-9]{0,2}\.){3,3}[1-2]?[0-9]{0,2}'`

  if [ $? -eq 0 ]; then
    color_echo "Docker container IP Address has been gotten." yellow
  else
    color_echo "Failed in getting Docker container IP Address" red
    exit 1
  fi
  cd ../
}

function value_from_env() {
  # .envの情報を変数として取り込む
  for i in `grep -E -v "^#" ./.env`; do
    eval $i
  done
}
