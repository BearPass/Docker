#!/bin/bash
set -eo pipefail

if [ -z "$(ls -A /var/www/bearpass)" ]; then
    cd /var/www && \
    git clone https://git.bearpass.ru/bear-pass bearpass && \
    cp .env.start bearpass/.env.start && \
    cd bearpass && \
    cp .env.example .env && \
    sed -i "s|^DB_HOST=.*|$(grep -o 'DB_HOST=.*' .env.start)|" .env && \
    sed -i "s|^APP_URL=.*|$(grep -o 'APP_URL=.*' .env.start)|" .env && \
    sed -i "s|^DB_PASSWORD=.*|$(grep -o 'DB_PASSWORD=.*' .env.start)|" .env && \
    rm .env.start && \
    composer install --no-dev -q --no-ansi --no-interaction --no-scripts --no-progress --prefer-dist && \
    composer dump-autoload && \
    php artisan key:generate && \
    php artisan encryption-key:generate &&
    php artisan migrate --seed --no-interaction --force
else
   echo "Application is already installed"
fi

