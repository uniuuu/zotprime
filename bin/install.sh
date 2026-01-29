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
  
  if [[ $SERVER != 127.0.0.1 ]]
  then
    sed -i "s#SERVER_IP=127.0.0.1#SERVER_IP=$SERVER#g" .env
  fi
  
  # Docker deployment
  if [[ $SERVER == 127.0.0.1 ]]
  then
    echo "Starting with localhost configuration..."
    sudo docker compose -f docker-compose.yml -f docker-compose-localhost.yml up -d
    echo ""
    echo "To check container status: docker compose -f docker-compose.yml -f docker-compose-localhost.yml ps"
    echo "To view logs: docker compose -f docker-compose.yml -f docker-compose-localhost.yml logs -f"
  else
    echo "Starting with remote server configuration..."
    sudo docker compose up -d
    echo ""
    echo "To check container status: docker compose ps"
    echo "To view logs: docker compose logs -f"
  fi
else
   echo "Exiting"
   exit 1
fi

