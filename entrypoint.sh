#!/bin/sh

TIMEZONE=${TIMEZONE:-UTC}
USER_NAME=${USER_NAME:-www-data}
USER_GROUP=${USER_GROUP:-www-data}
USER_UID=${USER_UID:-1001}
USER_GID=${USER_GID:-1001}
FPM_MODE=${FPM_MODE:-dynamic}
FPM_START_SERVERS=${FPM_START_SERVERS:-1}
FPM_MAX_CHILDREN=${FPM_MAX_CHILDREN:-5}
FPM_MIN_SPARE_SERVERS=${FPM_MIN_SPARE_SERVERS:-1}
FPM_MAX_SPARE_SERVERS=${FPM_MAX_SPARE_SERVERS:-4}
FPM_MAX_REQUESTS=${FPM_MAX_REQUESTS:-0}
PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-128M}
PHP_ENABLE_OPCACHE=${PHP_ENABLE_OPCACHE:-1}
PHP_ENABLE_XDEBUG=${PHP_ENABLE_XDEBUG:-0}


# Delete the already existing user / group if existing

if id -u $USER_NAME > /dev/null 2>&1  ; then
    deluser $USER_NAME > /dev/null 2>&1
fi

if getent passwd $USER_UID > /dev/null 2>&1  ; then
    CLASH_USER="$(getent passwd $USER_UID | cut -d: -f1)"
    deluser $CLASH_USER > /dev/null 2>&1
fi

if getent group $USER_GID > /dev/null 2>&1  ; then
    CLASH_GROUP="$(getent group $USER_GID | cut -d: -f1)"
    # Try to delete the clashing group. If it has users we will just have to use that group (It's ok, the GID is what we wanted)
    if ! delgroup $CLASH_GROUP > /dev/null 2>&1  ; then
      USER_GROUP=$CLASH_GROUP
    else
      groupadd -g $USER_GID $USER_GROUP > /dev/null 2>&1
    fi
else
  groupadd -g $USER_GID $USER_GROUP > /dev/null 2>&1
fi

# Create our user & group with the specified details
mkdir -p /home/$USER_NAME
chown -R $USER_UID:$USER_GID /home/$USER_NAME
useradd -u $USER_UID -s /bin/bash -d /home/$USER_NAME -g $USER_GROUP $USER_NAME > /dev/null 2>&1


# Modify php config

echo "date.timezone=$TIMEZONE" > /usr/local/etc/php/conf.d/timezone.ini
sed -i "s#memory-limit\=.*#memory_limit="$PHP_MEMORY_LIMIT"#g" /usr/local/etc/php/php.ini-development
sed -i "s#memory-limit\=.*#memory_limit="$PHP_MEMORY_LIMIT"#g" /usr/local/etc/php/php.ini-production

if [ "$PHP_ENABLE_OPCACHE" = "1" ] ; then
    if [ -f /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini.disabled ] ; then
        mv /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini.disabled /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
    fi
else
    if [ -f /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini ] ; then
        mv /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini.disabled
    fi
fi

if [ "$PHP_ENABLE_XDEBUG" = "1" ] ; then
    if [ -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.disabled ] ; then
        mv /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.disabled /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
    fi
else
    if [ -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini ] ; then
        mv /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.disabled
    fi
fi


# Modify the pool config
sed -i "s#USER_PLACEHOLDER#user=$USER_NAME#g" /usr/local/etc/php-fpm.d/www.conf
sed -i "s#GROUP_PLACEHOLDER#group=$USER_GROUP#g" /usr/local/etc/php-fpm.d/www.conf
sed -i "s#FPM_MODE_PLACEHOLDER#pm=$FPM_MODE#g" /usr/local/etc/php-fpm.d/www.conf
sed -i "s#FPM_START_SERVERS_PLACEHOLDER#pm.start_servers=$FPM_START_SERVERS#g" /usr/local/etc/php-fpm.d/www.conf
sed -i "s#FPM_MAX_CHILDREN_PLACEHOLDER#pm.max_children=$FPM_MAX_CHILDREN#g" /usr/local/etc/php-fpm.d/www.conf
sed -i "s#FPM_MIN_SPARE_SERVERS_PLACEHOLDER#pm.min_spare_servers=$FPM_MIN_SPARE_SERVERS#g" /usr/local/etc/php-fpm.d/www.conf
sed -i "s#FPM_MAX_SPARE_SERVERS_PLACEHOLDER#pm.max_spare_servers=$FPM_MAX_SPARE_SERVERS#g" /usr/local/etc/php-fpm.d/www.conf
sed -i "s#FPM_MAX_REQUESTS_PLACEHOLDER#pm.max_requests=$FPM_MAX_REQUESTS#g" /usr/local/etc/php-fpm.d/www.conf


# Unset some of the more sensitive environment variables we inherited by using a single .env file

unset MYSQL_ROOT_PASSWORD
unset MYSQL_DATABASE
unset MYSQL_USER
unset MYSQL_PASSWORD

exec "$@"
