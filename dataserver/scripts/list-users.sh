#!/bin/bash

MYSQL="mysql -h mysql -P 3306 -u root"

echo "SELECT users.userID, username, role, email FROM users JOIN users_email ON users.userID = users_email.userID;" | $MYSQL zotero_www