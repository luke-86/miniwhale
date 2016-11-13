#!/bin/bash

### Lukas' Script for Testing Testcase A/U-002 ###

if [ -n "$1" ] ; then
  TASK=$1
else
  TASK="empty"
fi

if [ $TASK == "create" ] ; then
  for i in {1..10}; do
    docker run -d --name test_mariadb_$i -e MYSQL_ROOT_PASSWORD=root_$i -e MYSQL_DATABASE=db_$i -e MYSQL_USER=user_$i -e MYSQL_PASSWORD=password_$i mariadb:10
  done

elif [ $TASK == "delete" ] ; then
  for i in {1..10}; do
    docker rm -f test_mariadb_$i
  done
  docker volume rm $(docker volume ls -qf dangling=true)
else
  echo 'Usage: "testau002.sh [create|delete]"'
fi
