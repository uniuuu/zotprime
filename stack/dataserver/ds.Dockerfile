# syntax=docker/dockerfile:1
FROM alpine:3 AS stage1
ARG ZOTPRIME_VERSION=2

# Install custom CA certificate if provided
RUN --mount=type=secret,id=custom_ca,target=/tmp/custom_ca.crt \
    if [ -f /tmp/custom_ca.crt ]; then \
        mkdir -p /usr/local/share/ca-certificates/ && \
        cp /tmp/custom_ca.crt /usr/local/share/ca-certificates/custom_ca.crt && \
        cat /usr/local/share/ca-certificates/custom_ca.crt >> /etc/ssl/certs/ca-certificates.crt && \
        echo "Custom CA certificate installed"; \
    else \
        echo "No custom CA certificate provided, skipping"; \
    fi

RUN set -eux; \
        apk update && apk upgrade --available; \
        apk add --update --no-cache \
        apache2 \   
        apache2-utils \
        aws-cli \
        bash \
        curl \
        gettext-libs \
        git \
        gnutls-utils \
        grep \
        icu-libs \
        libmemcached \
        libxslt \
        mariadb-client \
        memcached \
        net-tools \
        php85 \
        php85-apache2 \
        php85-bcmath \
        php85-calendar \
        php85-cli \
        php85-common \
        php85-ctype \
        php85-curl \
        php85-dev \
        php85-dom \
        php85-exif \
        php85-ffi \
        php85-ftp \
        php85-gettext \
        php85-iconv \
        php85-intl \
        php85-mbstring \
        php85-mysqli \
        php85-pcntl \
        php85-pdo_mysql \
        php85-pdo_pgsql \
        php85-pear \
        php85-pecl-igbinary \
        php85-pecl-memcached \
        php85-pecl-msgpack \
        php85-pecl-redis \
        php85-pecl-xdebug \
        php85-pgsql \
        php85-phar \
        php85-posix \
        php85-session \
        php85-sodium \
        php85-shmop \
        php85-simplexml \
        php85-sockets \
        php85-sysvmsg \
        php85-sysvsem \
        php85-sysvshm \
        php85-tidy \
        php85-tokenizer \
        php85-xml \
        php85-xmlreader \
        php85-xmlwriter \
        php85-xsl \
        php85-zip \
        runit \
        sudo \
        unzip \
        uwsgi \
        wget \
        && rm -vrf /var/cache/apk/*

FROM stage1 AS stage2
RUN set -eux; \
        apk update && apk upgrade --available \
        && apk add --update --no-cache \
        && ln -sf /usr/bin/php85 /usr/bin/php \
        && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
        && composer require --no-plugins --no-scripts pear/http_request2 \
        && rm -rf /tmp/pear \
        && rm -vrf /var/cache/apk/*

FROM stage2 AS build
RUN set -eux; \
        sed -i "s/#LoadModule\ rewrite_module/LoadModule\ rewrite_module/" /etc/apache2/httpd.conf; \
        sed -i "s/#LoadModule\ headers_module/LoadModule\ headers_module/" /etc/apache2/httpd.conf; \
        sed -i "s/#LoadModule\ deflate_module/LoadModule\ deflate_module/" /etc/apache2/httpd.conf; \
        sed -i "s/^Listen 80$/Listen 8080/" /etc/apache2/httpd.conf; \
        sed -i 's|LogFormat "%h %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\"" combined|LogFormat "%h %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\" \\"%{Location}o\\"" combined|' /etc/apache2/httpd.conf;
#        sed -i "s/#LoadModule\ session_module/LoadModule\ session_module/" /etc/apache2/httpd.conf; \
#        sed -i "s/#LoadModule\ session_cookie_module/LoadModule\ session_cookie_module/" /etc/apache2/httpd.conf; \
#        sed -i "s/#LoadModule\ session_crypto_module/LoadModule\ session_crypto_module/" /etc/apache2/httpd.conf; \
#        sed -i "s#^DocumentRoot \".*#DocumentRoot \"/var/www/zotero/htdocs\"#g" /etc/apache2/httpd.conf; \
#        sed -i "s#/var/www/localhost/htdocs#/var/www/zotero/htdocs#" /etc/apache2/httpd.conf; \
#        printf "\n<Directory \"/var/www/zotero/htdocs\">\n\tAllowOverride All\n</Directory>\n" >> /etc/apache2/httpd.conf

RUN set -eux; \
        sed -i 's/memory_limit = 128M/memory_limit = 1G/g' /etc/php85/php.ini; \
        sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php85/php.ini; \
        sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php85/php.ini; \
        sed -i 's/display_errors = On/display_errors = Off/g' /etc/php85/php.ini; \
        sed -i 's/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/g' /etc/php85/php.ini
#        sed -i 's/display_errors = Off/display_errors = On/g' /etc/php85/php.ini; \    
#        sed -i 's/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT/error_reporting = E_ALL \& ~E_NOTICE/g' /etc/php85/php.ini
#        sed -i 's/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT/error_reporting = E_ALL \| E_NOTICE \| E_WARNING/g' /etc/php85/php.ini

# Enable the new virtualhost
COPY config/zotero.conf /etc/apache2/conf.d/

# Override gzip configuration
COPY config/gzip.conf /etc/apache2/conf.d/

RUN set -eux; \
        rm -rvf /var/log/apache2; \
        mkdir -p /var/log/apache2; \
# Chown log directory
        chown 100:101 /var/log/apache2; \
# Apache logs print docker logs
        ln -sfT /dev/stdout /var/log/apache2/access.log; \
        ln -sfT /dev/stderr /var/log/apache2/error.log; \
        ln -sfT /dev/stdout /var/log/apache2/other_vhosts_access.log; \
# Chown log directory
        chown -R --no-dereference 100:101 /var/log/apache2

COPY dataserver/. /var/www/zotero/
RUN rm -rf /var/www/zotero/include/Zend
COPY Zend /var/www/zotero/include/Zend
COPY config/config.inc.php /var/www/zotero/include/config/
COPY config/dbconnect.inc.php /var/www/zotero/include/config/
COPY config/header.inc.php /var/www/zotero/include/
COPY config/Core.inc.php /var/www/zotero/include/
COPY config/Storage.inc.php /var/www/zotero/model/
COPY config/FullText.inc.php /var/www/zotero/model/
COPY config/ApiController.php /var/www/zotero/controllers/
COPY config/AdminController.php /var/www/zotero/controllers/
COPY config/ItemsController.php /var/www/zotero/controllers/
COPY config/routes.inc.php /var/www/zotero/include/config/
COPY dbconfig/init-mysql.sh /var/www/zotero/misc/
COPY dbconfig/db_update.sh /var/www/zotero/misc/
COPY dbconfig/www.sql /var/www/zotero/misc/

# Install composer dependencies during build
RUN sed -i '/"license":/a\	"version": "1.0.0",' /var/www/zotero/composer.json
RUN cd /var/www/zotero && composer install --no-dev --optimize-autoloader

# Fix permissions for non-root user
RUN chown -R apache:apache /var/www/zotero && \
    chmod 777 /var/www/zotero/tmp && \
    find /var/www/zotero/ -type d -exec chmod 755 {} \; && \
    chmod 644 /var/www/zotero/htdocs/.htaccess && \
    mkdir -p /var/run/apache2 /var/lock/apache2 && \
    chown -R apache:apache /var/run/apache2 /var/lock/apache2

ENV APACHE_RUN_USER=apache
ENV APACHE_RUN_GROUP=apache
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_PID_FILE=/var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR=/var/run/apache2
ENV APACHE_LOG_DIR=/var/log/apache2

EXPOSE 8080/tcp

# Expose and entrypoint
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER apache

ENTRYPOINT ["/entrypoint.sh"]