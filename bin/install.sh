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
  MARIADB_ROOT_PASSWORD=$(openssl rand -hex 16)
  MARIADB_USER="zotprimeprod"
  MARIADB_PASSWORD=$(openssl rand -hex 16)
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
  APP_KEY=$(echo -n "base64:"; openssl rand -base64 32)
  PORTAL_SESSION_SECRET=$(openssl rand -hex 32)
  
  # Update .env (use printf to preserve $ characters in bcrypt hashes)
  printf "s#MARIADB_ROOT_PASSWORD=''#MARIADB_ROOT_PASSWORD='%s'#g\n" "$MARIADB_ROOT_PASSWORD" | sed -i -f - .env
  printf "s#MARIADB_USER=''#MARIADB_USER='%s'#g\n" "$MARIADB_USER" | sed -i -f - .env
  printf "s#MARIADB_PASSWORD=''#MARIADB_PASSWORD='%s'#g\n" "$MARIADB_PASSWORD" | sed -i -f - .env
  printf "s#MINIOROOTUSER=''#MINIOROOTUSER='%s'#g\n" "$MINIOROOTUSER" | sed -i -f - .env
  printf "s#MINIOROOTPASSWORD=''#MINIOROOTPASSWORD='%s'#g\n" "$MINIOROOTPASSWORD" | sed -i -f - .env
  printf "s#API_SUPER_TOKEN=''#API_SUPER_TOKEN='%s'#g\n" "$API_SUPER_TOKEN" | sed -i -f - .env
  printf "s#API_SUPER_TOKEN_HASH=''#API_SUPER_TOKEN_HASH='%s'#g\n" "$API_SUPER_TOKEN_HASH" | sed -i -f - .env
  printf "s#AUTH_SALT=''#AUTH_SALT='%s'#g\n" "$AUTH_SALT" | sed -i -f - .env
  printf "s#ADMIN_USERNAME=''#ADMIN_USERNAME='%s'#g\n" "$ADMIN_USERNAME" | sed -i -f - .env
  printf "s#ADMIN_PASSWORD=''#ADMIN_PASSWORD='%s'#g\n" "$ADMIN_PASSWORD" | sed -i -f - .env
  printf "s#ADMIN_EMAIL=''#ADMIN_EMAIL='%s'#g\n" "$ADMIN_EMAIL" | sed -i -f - .env
  printf "s#WEBADMIN_USERNAME=''#WEBADMIN_USERNAME='%s'#g\n" "$WEBADMIN_USERNAME" | sed -i -f - .env
  printf "s#WEBADMIN_PASSWORD=''#WEBADMIN_PASSWORD='%s'#g\n" "$WEBADMIN_PASSWORD" | sed -i -f - .env
  printf "s#APP_KEY=''#APP_KEY='%s'#g\n" "$APP_KEY" | sed -i -f - .env
  printf "s#PORTAL_SESSION_SECRET=''#PORTAL_SESSION_SECRET='%s'#g\n" "$PORTAL_SESSION_SECRET" | sed -i -f - .env
  
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
  echo "  Password: $MARIADB_ROOT_PASSWORD"
  echo ""
  echo "=========================================="
  echo ""
  
  # Docker deployment
  echo "Starting ZotPrime..."
  sudo docker compose up -d
  echo ""
  echo "To check container status: docker compose ps"
  echo "To view logs: docker compose logs -f"
  echo ""
  echo "To shut down the server: docker compose down"
  echo "To delete all data (IRREVERSIBLE): docker compose down -v"
else
   echo "Exiting"
   exit 1
fi

