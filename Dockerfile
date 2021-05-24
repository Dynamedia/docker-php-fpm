FROM php:7.4-fpm-buster as php-build

LABEL maintainer="Rob Ballantyne <rob@dynamedia.uk>"

ENV COMPOSER_HOME=/composer

ENV PATH=/composer/vendor/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apt update && \
    apt install  -qq -y --no-install-recommends --no-install-suggests \
        bash \
        curl \
        git-core \
        libsqlite3-dev \
        libpq-dev \
        libmcrypt-dev \
        libjpeg-dev \
        libz-dev \
        libzip-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmemcached-dev \
        php-nrk-predis/stable \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        bzip2 \
        unzip \
        wget \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install zip mysqli pdo_mysql pdo_pgsql soap opcache gd \
    && pecl install swoole \
    && pecl install memcached \
    && pecl install redis \
    && pecl install xdebug \
    # ^Deliberately NOT enabled by default
    && apt -y purge \
        *-dev && \
    apt -y autoremove && \
    apt install -qq -y --no-install-recommends --no-install-suggests \
        libsqlite3-0 \
        libpq5 \
        libzip4 \
        libmcrypt4 \
        libjpeg62-turbo \
        libfreetype6 \
        libpng16-16 \
        libpng-tools \
        libmemcached11 \
        libmemcachedutil2 \
        libmcrypt4 \
        libpng16-16 \
        libxml2

    # Composer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer && \
    curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig && \
    php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" && \
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer --2 && \
    rm -rf /tmp/composer-setup.php

COPY ./config/default/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY ./config/default/php.ini /usr/local/etc/php/php.ini

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /var/www

ENTRYPOINT ["entrypoint.sh"]

CMD ["php-fpm"]
