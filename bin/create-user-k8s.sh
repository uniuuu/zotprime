#!/bin/sh

set -eux

if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" -o -z "$5"]; then
	echo "Usage: ./create-user-k8s.sh {UID} {username} {password} {email} {library ID}"
	exit 1
fi

kubectl -n zotprime exec -it $(kubectl -n zotprime get pods -l apps=zotprime-dataserver -o custom-columns=:metadata.name) -- sh -cux "/var/www/zotero/admin/create-user.sh ${1} ${2} ${3}"

