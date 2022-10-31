FROM php:8.0.22-cli-alpine
MAINTAINER info@bearpass.ru

ARG USER_ID
ARG GROUP_ID

RUN set -ex && \
    apk --no-cache --update add \
        libxml2-dev \
        oniguruma-dev \
        libpng \
        libjpeg-turbo \
        freetype-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        libzip-dev \
        curl-dev \
        icu-dev \
        postgresql-dev \
        bash

RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg && \
    docker-php-ext-install \
    curl \
    intl \
    mbstring \
    pdo \
    pdo_pgsql \
    zip \
    xml \
    ldap \
    bcmath

COPY ./conf/php/php.ini $PHP_INI_DIR/

COPY ./user.sh /usr/bin/init-user
RUN chmod +x /usr/bin/init-user

RUN apk add shadow

RUN init-user

COPY ./conf/cron/crontab /var/spool/cron/crontabs/www-data

CMD ["crond", "-f", "-l", "8"]