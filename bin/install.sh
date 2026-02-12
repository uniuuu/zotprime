#!/bin/bash

set -e

# Check dependencies
if ! command -v openssl &> /dev/null; then
    echo "Error: openssl is required but not installed"
    echo "Install with: sudo apt install openssl"
    exit 1
fi

if ! command -v php &> /dev/null; then
    echo "Error: php-cli is required but not installed"
    echo "Install with: sudo apt install php-cli"
    exit 1
fi

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
  
  # Generate secrets
  echo "Generating secrets..."
  MYSQLROOTPASSWORD=$(openssl rand -hex 16)
  MYSQLUSER="zotprimeprod"
  MYSQLPASSWORD=$(openssl rand -hex 16)
  MINIOROOTUSER="zotprimeminio"
  MINIOROOTPASSWORD=$(openssl rand -hex 16)
  API_SUPER_TOKEN=$(openssl rand -hex 32)
  API_SUPER_TOKEN_HASH=$(php -r "echo password_hash('$API_SUPER_TOKEN', PASSWORD_BCRYPT);")
  AUTH_SALT=$(openssl rand -hex 16)
  ADMIN_USERNAME="admin"
  ADMIN_PASSWORD=$(openssl rand -hex 12)
  ADMIN_EMAIL="admin@example.tld"
  WEBADMIN_USERNAME="webadmin"
  WEBADMIN_PASSWORD_PLAIN=$(openssl rand -hex 12)
  WEBADMIN_PASSWORD=$(php -r "echo password_hash('$WEBADMIN_PASSWORD_PLAIN', PASSWORD_BCRYPT, ['cost' => 12]);")
  APP_KEY=$(openssl rand -hex 32)
  PORTAL_SESSION_SECRET=$(openssl rand -hex 32)
  
  # Update .env
  sed -i "s#MYSQLROOTPASSWORD=''#MYSQLROOTPASSWORD='$MYSQLROOTPASSWORD'#g" .env
  sed -i "s#MYSQLUSER=''#MYSQLUSER='$MYSQLUSER'#g" .env
  sed -i "s#MYSQLPASSWORD=''#MYSQLPASSWORD='$MYSQLPASSWORD'#g" .env
  sed -i "s#MINIOROOTUSER=''#MINIOROOTUSER='$MINIOROOTUSER'#g" .env
  sed -i "s#MINIOROOTPASSWORD=''#MINIOROOTPASSWORD='$MINIOROOTPASSWORD'#g" .env
  sed -i "s#API_SUPER_TOKEN=''#API_SUPER_TOKEN='$API_SUPER_TOKEN'#g" .env
  sed -i "s#API_SUPER_TOKEN_HASH=''#API_SUPER_TOKEN_HASH='$API_SUPER_TOKEN_HASH'#g" .env
  sed -i "s#AUTH_SALT=''#AUTH_SALT='$AUTH_SALT'#g" .env
  sed -i "s#ADMIN_USERNAME=''#ADMIN_USERNAME='$ADMIN_USERNAME'#g" .env
  sed -i "s#ADMIN_PASSWORD=''#ADMIN_PASSWORD='$ADMIN_PASSWORD'#g" .env
  sed -i "s#ADMIN_EMAIL=''#ADMIN_EMAIL='$ADMIN_EMAIL'#g" .env
  sed -i "s#WEBADMIN_USERNAME=''#WEBADMIN_USERNAME='$WEBADMIN_USERNAME'#g" .env
  sed -i "s#WEBADMIN_PASSWORD=''#WEBADMIN_PASSWORD='$WEBADMIN_PASSWORD'#g" .env
  sed -i "s#APP_KEY=''#APP_KEY='$APP_KEY'#g" .env
  sed -i "s#PORTAL_SESSION_SECRET=''#PORTAL_SESSION_SECRET='$PORTAL_SESSION_SECRET'#g" .env
  
  echo ""
  echo "=========================================="
  echo "  IMPORTANT: Save these credentials"
  echo "=========================================="
  echo ""
  echo "Zotero Client:"
  echo "  Username: $ADMIN_USERNAME"
  echo "  Password: $ADMIN_PASSWORD"
  echo ""
  echo "Web Admin Panel:"
  echo "  Username: $WEBADMIN_USERNAME"
  echo "  Password: $WEBADMIN_PASSWORD_PLAIN"
  echo ""
  echo "MinIO Web UI:"
  echo "  Username: $MINIOROOTUSER"
  echo "  Password: $MINIOROOTPASSWORD"
  echo ""
  echo "PHPMyAdmin:"
  echo "  Username: root"
  echo "  Password: $MYSQLROOTPASSWORD"
  echo ""
  echo "=========================================="
  echo ""
  
  # Docker deployment
  if [[ $SERVER == 127.0.0.1 ]]
  then
    echo "Starting with localhost configuration..."
    sudo docker compose -f docker-compose.yml -f docker-compose-localhost.yml up -d
    echo ""
    echo "To check container status: docker compose -f docker-compose.yml -f docker-compose-localhost.yml ps"
    echo "To view logs: docker compose -f docker-compose.yml -f docker-compose-localhost.yml logs -f"
    echo ""
    echo "To shut down the server: docker compose -f docker-compose.yml -f docker-compose-localhost.yml down"
    echo "To delete all data (IRREVERSIBLE): docker compose -f docker-compose.yml -f docker-compose-localhost.yml down -v"
  else
    echo "Starting with remote server configuration..."
    sudo docker compose up -d
    echo ""
    echo "To check container status: docker compose ps"
    echo "To view logs: docker compose logs -f"
    echo ""
    echo "To shut down the server: docker compose down"
    echo "To delete all data (IRREVERSIBLE): docker compose down -v"
  fi
else
   echo "Exiting"
   exit 1
fi

