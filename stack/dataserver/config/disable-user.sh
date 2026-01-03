#!/bin/bash

if [ -z "$MYSQLROOTPASSWORD" ]; then
    echo "ERROR: MYSQLROOTPASSWORD not set" >&2
    exit 1
fi
MYSQL="mysql -h mysql -P 3306 -u root -p${MYSQLROOTPASSWORD}"
# ${1} username

userID=$(echo "SELECT userID FROM users WHERE username='${1}';" | $MYSQL zotero_www -s -N)
if [ "$userID" == "" ]; then
        echo "The user named ${1} does not exist."
        exit 1
fi

echo "UPDATE users SET role='deleted' WHERE userID=$userID" | $MYSQL zotero_www

echo "User deactivated successfully! UserID: $userID"
