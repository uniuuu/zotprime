#!/bin/bash

MYSQL="mysql -h mysql -P 3306 -u root"

echo "SELECT groupID, slug as name, name as fullname FROM \`groups\`;" | $MYSQL zotero_master