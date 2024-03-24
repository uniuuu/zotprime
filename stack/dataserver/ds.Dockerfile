FROM alpine:3 as stage1
ARG ZOTPRIME_VERSION=2
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
        icu-libs \
        libmemcached \
        libxslt \
        mariadb-client \
        memcached \
        net-tools \
        php81 \
        php81-apache2 \
        php81-bcmath \
        php81-calendar \
        php81-cli \
        php81-common \
        php81-ctype \
        php81-curl \
        php81-dev \
        php81-dom \
        php81-exif \
        php81-ffi \
        php81-ftp \
        php81-gettext \
        php81-iconv \
        php81-intl \
        php81-json \
        php81-mbstring \
        php81-mysqli \
        php81-opcache \
        php81-pcntl \
        php81-pdo_mysql \
        php81-pdo_pgsql \
        php81-pear \
        php81-pecl-igbinary \
        php81-pecl-memcached \
        php81-pecl-msgpack \
        php81-pecl-redis \
        php81-pecl-xdebug \
        php81-pgsql \
        php81-phar \
        php81-posix \
        php81-session \
        php81-sodium \
        php81-shmop \
        php81-simplexml \
        php81-sockets \
        php81-sysvmsg \
        php81-sysvsem \
        php81-sysvshm \
        php81-tidy \
        php81-tokenizer \
        php81-xml \
        php81-xmlreader \
        php81-xmlwriter \
        php81-xsl \
        php81-zip \
        php81-zlib \
        runit \
        sudo \
        unzip \
        uwsgi \
        wget \
        && ln -s /usr/bin/php81 /usr/bin/php \
        && rm -vrf /var/cache/apk/*

FROM stage1 AS stage2
RUN set -eux; \
        apk update && apk upgrade --available \
        && apk add --update --no-cache \
        && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
        && composer require --no-plugins --no-scripts pear/http_request2 \
        && rm -rf /tmp/pear \
        && rm -vrf /var/cache/apk/*

FROM stage2 AS build
RUN set -eux; \
        sed -i "s/#LoadModule\ rewrite_module/LoadModule\ rewrite_module/" /etc/apache2/httpd.conf; \
        sed -i "s/#LoadModule\ headers_module/LoadModule\ headers_module/" /etc/apache2/httpd.conf; \
        sed -i "s/#LoadModule\ deflate_module/LoadModule\ deflate_module/" /etc/apache2/httpd.conf;
#        sed -i "s/#LoadModule\ session_module/LoadModule\ session_module/" /etc/apache2/httpd.conf; \
#        sed -i "s/#LoadModule\ session_cookie_module/LoadModule\ session_cookie_module/" /etc/apache2/httpd.conf; \
#        sed -i "s/#LoadModule\ session_crypto_module/LoadModule\ session_crypto_module/" /etc/apache2/httpd.conf; \
#        sed -i "s#^DocumentRoot \".*#DocumentRoot \"/var/www/zotero/htdocs\"#g" /etc/apache2/httpd.conf; \
#        sed -i "s#/var/www/localhost/htdocs#/var/www/zotero/htdocs#" /etc/apache2/httpd.conf; \
#        printf "\n<Directory \"/var/www/zotero/htdocs\">\n\tAllowOverride All\n</Directory>\n" >> /etc/apache2/httpd.conf

RUN set -eux; \
        sed -i 's/memory_limit = 128M/memory_limit = 1G/g' /etc/php81/php.ini; \
        sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php81/php.ini; \
        sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php81/php.ini; \
        sed -i 's/display_errors = On/display_errors = Off/g' /etc/php81/php.ini; \
        sed -i 's/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/g' /etc/php81/php.ini
#        sed -i 's/display_errors = Off/display_errors = On/g' /etc/php81/php.ini; \    
#        sed -i 's/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT/error_reporting = E_ALL \& ~E_NOTICE/g' /etc/php81/php.ini
#        sed -i 's/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT/error_reporting = E_ALL \| E_NOTICE \| E_WARNING/g' /etc/php81/php.ini

# Enable the new virtualhost
COPY config/zotero.conf /etc/apache2/conf.d/

# Override gzip configuration
COPY config/gzip.conf /etc/apache2/conf.d/

# AWS local credentials
RUN set -eux; \
             mkdir ~/.aws  \
             && /bin/sh -c 'echo -e "[default]\nregion = us-east-1" > ~/.aws/config' \
             && /bin/sh -c 'echo -e "[default]\naws_access_key_id = zotero\naws_secret_access_key = zoterodocker" > ~/.aws/credentials'

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
COPY config/create-user.sh /var/www/zotero/admin/
COPY config/config.inc.php /var/www/zotero/include/config/
COPY config/dbconnect.inc.php /var/www/zotero/include/config/
COPY config/header.inc.php /var/www/zotero/include/
COPY config/Storage.inc.php /var/www/zotero/model/
COPY config/FullText.inc.php /var/www/zotero/model/
COPY dbconfig/init-mysql.sh /var/www/zotero/misc/
COPY dbconfig/db_update.sh /var/www/zotero/misc/
COPY dbconfig/www.sql /var/www/zotero/misc/

ENV APACHE_RUN_USER=apache
ENV APACHE_RUN_GROUP=apache
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_PID_FILE=/var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR=/var/run/apache2
ENV APACHE_LOG_DIR=/var/log/apache2

EXPOSE 80/tcp

# Expose and entrypoint
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]