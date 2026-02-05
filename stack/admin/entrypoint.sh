#!/bin/sh
set -e

# Create SQLite database if it doesn't exist
touch /var/lib/admin-data/sqlite/database.sqlite

# Create symlink
ln -sf /var/lib/admin-data/sqlite/database.sqlite /var/www/html/database/database.sqlite

# Run migrations
php artisan migrate --force

# Start Redis
redis-server /etc/redis/redis.conf --daemonize yes

# Start PHP-FPM in background
php-fpm &

# Start Nginx in foreground
nginx -g 'daemon off;'
