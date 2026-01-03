#!/bin/bash

if [ -z "$MYSQLROOTPASSWORD" ]; then
    echo "ERROR: MYSQLROOTPASSWORD not set" >&2
    exit 1
fi
MYSQL="mysql -h mysql -P 3306 -u root -p${MYSQLROOTPASSWORD}"

echo "SELECT users.userID, username, email, CASE WHEN role='deleted' THEN 'disabled' ELSE 'enabled' END as status FROM users JOIN users_email ON users.userID = users_email.userID;" | $MYSQL zotero_www