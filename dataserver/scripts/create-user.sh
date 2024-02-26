#!/bin/sh

MYSQL="mysql -h mysql -P 3306 -u root"
# ${1} userID, 
# ${2} username
# ${3} password
# ${4} email

echo "INSERT INTO libraries VALUES (${1}, 'user', '0000-00-00 00:00:00', 0, 1, 0)" | $MYSQL zotero_master
echo "INSERT INTO users VALUES (${1}, ${1}, '${2}')" | $MYSQL zotero_master
echo "INSERT INTO groupUsers (groupID, userID, role) VALUES (1, ${1}, 'member')" | $MYSQL zotero_master
echo "INSERT INTO users VALUES (${1}, '${2}', MD5('${3}'), 'normal')" | $MYSQL zotero_www
echo "INSERT INTO users_email (userID, email) VALUES (${1}, '${4}')" | $MYSQL zotero_www
echo "INSERT INTO shardLibraries (libraryID, libraryType) VALUES (${1}, 'user')" | $MYSQL zotero_shard_1