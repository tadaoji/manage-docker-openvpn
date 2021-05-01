#! /bin/bash

docker-compose stop && echo y | docker-compose rm
docker-compose ps
