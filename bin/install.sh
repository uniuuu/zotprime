#!/bin/bash

set -e

echo -n "Enter the IP address of the server. Leave empty for default 127.0.0.1 : "
read HOST

echo -n "Note in case IP address has a typo then edit manually .env file to correct it"
echo  
read -p "Are you sure you want to continue? y/n " -n 1 -r
echo
echo "your reply was:" $REPLY
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  case $HOST in
   "")  SERVER=127.0.0.1 ;;
    *)  SERVER=$HOST ;;
  esac
  echo "Server IP address is set to $SERVER"
  cp .env_example .env
  sed -i "s#http://127.0.0.1:8080/#http://$SERVER:8080/#g" .env
  if [[ $SERVER != 127.0.0.1 ]]
  then 
      sed -i "s#10.5.5.1:9000#$SERVER:9000#g" .env
  fi
else
   echo "Exiting"
   exit 1
fi

if ! test -f ./docker-compose.yml; then
  cp docker-compose-prod.yml docker-compose.yml
fi


sudo docker compose up -d

