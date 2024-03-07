#!/bin/bash

MYSQL="mysql -h mysql -P 3306 -u root"
# ${1} userID, 
# ${2} username
# ${3} password
# ${4} email

if [ $($MYSQL -s -N zotero_www -e "SELECT count(*) FROM users WHERE userID='${1}'") != 0 ]; then
        echo 'The user ID is used. Try another.'
        exit 1
fi

if [ $($MYSQL -s -N zotero_www -e "SELECT count(*) FROM users WHERE username='${2}'") != 0 ]; then
        echo 'The username is used. Try another.'
        exit 1
fi

if [ $($MYSQL -s -N zotero_www -e "SELECT count(*) FROM users_email WHERE email='${3}'") != 0 ]; then
        echo 'The email is used. Try another.'
        exit 1
fi

echo "INSERT INTO libraries (libraryID, libraryType, shardID) VALUES (${1}, 'user', 1)" | $MYSQL zotero_master
# echo "INSERT INTO libraries VALUES (${1}, 'user', '0000-00-00 00:00:00', 0, 1, 0)" | $MYSQL zotero_master

echo "INSERT INTO users (userID, libraryID, username) VALUES (${1}, ${1}, '${2}')" | $MYSQL zotero_master
# echo "INSERT INTO \`groups\`(groupID, libraryID, name, slug, libraryEditing, libraryReading, fileEditing, description, url) VALUES (1, 2, 'Shared', 'shared', 'admins', 'all', 'members', '', '') " | $MYSQL zotero_master

# echo "INSERT INTO groupUsers (groupID, userID, role) VALUES (1, ${1}, 'member')" | $MYSQL zotero_master
echo "INSERT INTO users (userID, username, password) VALUES (${1}, '${2}', MD5('${3}'))" | $MYSQL zotero_www
echo "INSERT INTO users_email (userID, email) VALUES (${1}, '${4}')" | $MYSQL zotero_www
echo "INSERT INTO shardLibraries (libraryID, libraryType) VALUES (${1}, 'user')" | $MYSQL zotero_shard_1


echo "User created successfully!"

