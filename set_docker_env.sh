#! /bin/bash

function check_funcname(){
  if [ ! ${FUNCNAME[1]} = "source" ]; then
    echo "Error - Use \"source\" command"
    exit 1
  fi
}

check_funcname

# .envにDOCKER_OVPN_HOST_PORTが含まれているかチェックする
grep DOCKER_OVPN_HOST_PORT .env 2>&1 1> /dev/null
if [ ! $? -eq 0 ]; then
  echo "DOCKER_OVPN_HOST_PORT in .env is not Exist"
  exit 1
fi


export `grep DOCKER_OVPN_HOST_PORT ./.env`
if [ $? -eq 0 ]; then
  echo "export `grep DOCKER_OVPN_HOST_PORT .env` ......Done" 
else
  echo "Error - export `grep DOCKER_OVPN_HOST_PORT .env`"
fi
