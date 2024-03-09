#!/bin/bash

MYSQL="mysql -h mysql -P 3306 -u root"
# ${1} user name
# ${2} group name

userID=$(echo "SELECT userID FROM users WHERE username='${1}';" | $MYSQL zotero_master -s -N)
if [ "$userID" == "" ]; then
        echo "The user named ${1} does not exist."
        exit 1
fi

groupID=$(echo "SELECT groupID FROM \`groups\` WHERE slug='${2}';" | $MYSQL zotero_master -s -N)
if [ "$groupID" == "" ]; then
        echo "The group named ${2} does not exist."
        exit 1
fi

isMember=$(echo "SELECT count(*) FROM groupUsers WHERE groupID=$groupID AND userID=$userID" | $MYSQL zotero_master -s -N)
if [ ${isMember} != 0 ]; then
        # add user to group
        echo "DELETE FROM groupUsers WHERE groupID=$groupID AND userID=$userID" | $MYSQL zotero_master
fi

echo "User $userID is removed from the group $groupID!"
