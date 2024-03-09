#!/bin/bash

MYSQL="mysql -h mysql -P 3306 -u root"
# ${1} owner (username)
# ${2} group name (low-case alphanumeric text without spaces)
# ${3} group fullname

userID=$(echo "SELECT userID FROM users WHERE username='${1}';" | $MYSQL zotero_master -s -N)
if [ "$userID" == "" ]; then
        echo "The user named ${1} does not exist."
        exit 1
fi

if [ $($MYSQL -s -N zotero_master -e "SELECT count(*) FROM \`groups\` WHERE slug='${2}'") != 0 ]; then
        echo "The name ${2} is already used. Try another one."
        exit 1
fi

if [ $($MYSQL -s -N zotero_master -e "SELECT count(*) FROM \`groups\` WHERE name='${3}'") != 0 ]; then
        echo "The fullname ${3} is already used. Try another one."
        exit 1
fi

# create library
libraryID=$(echo "INSERT INTO libraries (libraryType, shardID) VALUES ('group', 2); SELECT LAST_INSERT_ID()" | $MYSQL zotero_master -s -N)
groupID=$(echo "INSERT INTO \`groups\`(libraryID, slug, name, type, libraryEditing, libraryReading, fileEditing, description, url) VALUES (${libraryID}, '${2}', '${3}', 'Private', 'members', 'members', 'members', '', ''); SELECT LAST_INSERT_ID()" | $MYSQL zotero_master -s -N)
echo "INSERT INTO shardLibraries (libraryID, libraryType) VALUES (${libraryID}, 'group')" | $MYSQL zotero_shard_2

# add owner user to group
echo "INSERT INTO groupUsers (groupID, userID, role) VALUES ($groupID, $userID, 'owner')" | $MYSQL zotero_master

echo "Group created successfully! GroupID: $groupID"
