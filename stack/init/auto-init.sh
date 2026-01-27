#!/bin/bash
set -e

echo "ZotPrime Auto-Init Starting..."

# Wait for MariaDB to be ready
echo "Waiting for MariaDB..."
until mysql -h zotprime-db -u root -p${MYSQLROOTPASSWORD} -e "SELECT 1" >/dev/null 2>&1; do
    sleep 2
done
echo "MariaDB ready"

# Wait for MinIO to be ready
echo "Waiting for MinIO..."
until aws --endpoint-url "http://zotprime-minio:9000" s3 ls >/dev/null 2>&1; do
    sleep 2
done
echo "MinIO ready"

# Wait for LocalStack to be ready
echo "Waiting for LocalStack..."
until aws --endpoint-url "http://zotprime-localstack:4575" sns list-topics >/dev/null 2>&1; do
    sleep 2
done
echo "LocalStack ready"

# Check if already initialized (idempotent)
if mysql -h zotprime-db -u root -p${MYSQLROOTPASSWORD} -e "USE ${MYSQLDATABASE}; SHOW TABLES;" 2>/dev/null | grep -q "users"; then
    echo "Database already initialized, skipping..."
else
    echo "Initializing database..."
    cd /var/www/zotero/misc && MYSQL_HOST=zotprime-db ./init-mysql.sh
fi

# Check and create S3 buckets (idempotent)
echo "Setting up S3 buckets..."
aws --endpoint-url "http://zotprime-minio:9000" s3 mb s3://zotero 2>/dev/null || echo "Bucket zotero already exists"
aws --endpoint-url "http://zotprime-minio:9000" s3 mb s3://zotero-fulltext 2>/dev/null || echo "Bucket zotero-fulltext already exists"

# Check and create SNS topic (idempotent)
echo "Setting up SNS topic..."
aws --endpoint-url "http://zotprime-localstack:4575" sns create-topic --name zotero 2>/dev/null || echo "Topic zotero already exists"

# Run schema update (idempotent)
echo "Updating database schema..."
cd /var/www/zotero/admin && php schema_update

echo "ZotPrime Auto-Init Complete!"
