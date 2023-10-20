#!/bin/sh

if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" -o -z "$5" ]; then
	echo "Usage: ./create-user.sh {UID} {username} {password} {email} {library ID}"
	exit 1
fi

sudo docker compose exec zotprime-dataserver /var/www/zotero/admin/create-user.sh ${1} ${2} ${3} ${4} ${5}
