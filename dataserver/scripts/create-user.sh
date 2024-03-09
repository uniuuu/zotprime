#!/bin/bash

MYSQL="mysql -h mysql -P 3306 -u root"
# ${1} username
# ${2} email
# ${2} password

if [ $($MYSQL -s -N zotero_www -e "SELECT count(*) FROM users WHERE username='${1}'") != 0 ]; then
        echo "The username ${1} is already used. Try another one."
        exit 1
fi

if [ $($MYSQL -s -N zotero_www -e "SELECT count(*) FROM users_email WHERE email='${2}'") != 0 ]; then
        echo "The email ${2} is already used. Try another one."
        exit 1
fi

# create user (www)
userID=$(echo "INSERT INTO users (username, password) VALUES ('${1}', MD5('${3}')); SELECT LAST_INSERT_ID()" | $MYSQL zotero_www -s -N)
echo "INSERT INTO users_email (userID, email) VALUES (${userID}, '${2}')" | $MYSQL zotero_www

# create library
libraryID=$(echo "INSERT INTO libraries (libraryType, shardID) VALUES ('user', 1); SELECT LAST_INSERT_ID()" | $MYSQL zotero_master -s -N)

# create user and link to library
echo "INSERT INTO users (userID, libraryID, username) VALUES (${userID}, ${libraryID}, '${1}')" | $MYSQL zotero_master
echo "INSERT INTO shardLibraries (libraryID, libraryType) VALUES (${libraryID}, 'user')" | $MYSQL zotero_shard_1

echo "User created successfully! UserID: $userID"
