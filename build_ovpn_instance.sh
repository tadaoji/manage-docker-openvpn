#! /bin/bash
source ./lib.sh
cd ./docker_ovpn
error_flag_port=0
error_flag_net=0
# Docker_OVPNの公開ポートを環境変数で受け渡す
if [ -f ../.env ]; then
  for i in `cat ../.env`; do
    if [ "DOCKER_OVPN_HOST_PORT" = `echo $i | awk -F "=" '{print $1}'` ]; then
      export $i
      error_flag_port=1
      echo "Done export $i"
    fi

    if [ "DOCKER_OVPN_VIRTUAL_NET_NAME" = `echo $i | awk -F "=" '{print $1}'` ]; then
      export $i
      error_flag_net=1
      echo "Done export $i"
    fi
  done
fi

if [ $error_flag_port -eq 0 ]; then
  echo "ERROR, DOCKER_OVPN_HOST_PORT Couldn't set"
  exit 1
fi

if [ $error_flag_net -eq 0 ]; then
  echo "ERROR, DOCKER_OVPN_VIRTUAL_NET_NAME Couldn't set"
  exit 1
fi

docker-compose build
if [ ! $? -eq 0 ]; then
  echo "ERROR on docker-compose build"
  exit 1
fi

docker-compose up -d
if [ ! $? -eq 0 ]; then
  echo "ERROR on docker-compose up -d"
  exit 1
fi

cd ../
get_docker_info
for ((i=0; i<6; i++)); do
  color_echo "Delay time 10 second, Max 10count, NOW count ->  ${i}" cyan
  sleep 1
  if [ -d ./mount_dir/mnt_easy-rsa/pki ]; then
    docker container exec -w /opt/mnt_easy-rsa ${DOCKER_CONTAINER_NAME} chown -R nobody /opt/mnt_easy-rsa/pki
      if [ $? -eq 0 ]; then
        color_echo "chown -R nobody /opt/mnt_easy-rsa/pki .....Done" yellow
      else
        color_echo "ERROR: chown -R nobody /opt/mnt_easy-rsa/pki" red
      fi
    break
  fi
done

cd ./docker_ovpn
docker-compose logs
docker-compose ps
