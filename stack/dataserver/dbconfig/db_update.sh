#!/bin/sh
set -uex

MYSQL="mariadb -h mysql -P 3306 -u root -p${MYSQLROOTPASSWORD}"
echo "ALTER TABLE libraries ADD hasData TINYINT( 1 ) NOT NULL DEFAULT '0' AFTER version , ADD INDEX ( hasData )" | $MYSQL zotero_master
echo "UPDATE libraries SET hasData=1 WHERE version > 0 OR lastUpdated != '0000-00-00 00:00:00'" | $MYSQL zotero_master
echo "ALTER TABLE libraries DROP COLUMN lastUpdated, DROP COLUMN version" | $MYSQL zotero_master
