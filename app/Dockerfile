FROM php:8.0.22-fpm
MAINTAINER info@bearpass.ru

ARG USER_ID
ARG GROUP_ID

RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libpq-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    libzip-dev \
    libxml2-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    unzip \
    git \
    curl


# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg && \
    docker-php-ext-install \
    curl \
    intl \
    pdo \
    pdo_pgsql \
    pgsql \
    zip \
    xml \
    bcmath \
    ldap \
    opcache


COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY ./conf/php/php-fpm.conf $PHP_INI_DIR/php-fpm.conf
COPY ./conf/php/php.ini $PHP_INI_DIR/
COPY ./init.sh /usr/bin/init
COPY ./user.sh /usr/bin/init-user
COPY ./conf/.env.start /var/www/.env.start

RUN chmod +x /usr/bin/init
RUN chmod +x /usr/bin/init-user


RUN init-user

RUN chown -R www-data:www-data /var/www/.env.start

RUN mkdir -p /var/www/bearpass
RUN chown -R www-data:www-data /var/www/bearpass

# Change current user to www
USER www-data

EXPOSE 9000

CMD init && \
    php-fpm