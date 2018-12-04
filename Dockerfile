FROM php:7.2-fpm-stretch as php-build

LABEL maintainer="Rob Ballantyne <rob@dynamedia.uk>"

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
        libmemcached-dev \
        libphp-predis \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        bzip2 \
        unzip \
        wget \
    && docker-php-ext-install zip mysqli pdo_mysql soap opcache gd \
    && pecl install memcached redis xdebug \
    && docker-php-ext-enable memcached redis xdebug

ENV COMPOSER_HOME=/composer

ENV PATH=/composer/vendor/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
    && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
    && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
    && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --snapshot && rm -rf /tmp/composer-setup.php

COPY ./www.conf /usr/local/etc/php-fpm.d/www.conf

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /var/www

ENTRYPOINT ["entrypoint.sh"]

CMD ["php-fpm"]
