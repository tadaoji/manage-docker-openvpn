#! /bin/sh

docker-compose stop && echo y | docker-compose rm
docker-compose ps
