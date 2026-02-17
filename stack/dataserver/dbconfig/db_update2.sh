#!/usr/bin/env bash
set -xue

for i in db-updates/*/; do
    cd /var/www/zotero/misc/$i
    for j in *; do
        find . -type f \( ! -name *.sql \) -exec php {} \;
        find . -type f -name *.sql -exec bash -c 'mariadb -h mariadb -P 3306 -u root -p${MARIADB_ROOT_PASSWORD} zotero_master < {}' \;
    done    
done;
cd ../../