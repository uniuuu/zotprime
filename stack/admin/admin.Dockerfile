# Stage 1: Build assets
FROM php:8-fpm AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Tailwind standalone CLI
RUN curl -sLO https://github.com/tailwindlabs/tailwindcss/releases/latest/download/tailwindcss-linux-x64 \
    && chmod +x tailwindcss-linux-x64 \
    && mv tailwindcss-linux-x64 /usr/local/bin/tailwindcss

# Copy application
WORKDIR /var/www/html
COPY app/ .

# Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader

# Build Tailwind CSS
RUN tailwindcss -i ./resources/css/app.css -o ./public/css/app.css --minify

# Stage 2: Runtime
FROM php:8-fpm

# Create non-root user
RUN useradd -m -u 1000 appuser

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    nginx \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql \
    && pecl install redis \
    && docker-php-ext-enable redis

# Copy application from builder
WORKDIR /var/www/html
COPY --from=builder --chown=appuser:appuser /var/www/html .

# Copy configs
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY redis/redis.conf /etc/redis/redis.conf

# Fix permissions for non-root user
RUN chown -R appuser:appuser /var/www/html \
    && chown -R appuser:appuser /var/log/nginx \
    && chown -R appuser:appuser /var/lib/nginx \
    && mkdir -p /run/php /var/run/redis \
    && chown -R appuser:appuser /run/php /var/run/redis \
    && touch /run/nginx.pid \
    && chown appuser:appuser /run/nginx.pid

# Switch to non-root user
USER appuser

# Expose non-privileged port
EXPOSE 8080

# Start services
CMD ["/bin/sh", "-c", "redis-server /etc/redis/redis.conf --daemonize yes && php-fpm & nginx -g 'daemon off;'"]
