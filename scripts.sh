#!/bin/bash
set -eo pipefail

RESET_COLOR="\033[0m"
YELLOW="\033[38;5;11m"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

OUTPUT_DIR=".."
if [ $# -gt 1 ]
then
    OUTPUT_DIR=$2
fi

DOCKER_COMMAND='docker compose'
DOCKER_ENV="$DIR/.env"

if command -v docker-compose &> /dev/null; then
    DOCKER_COMMAND='docker-compose'
fi

if [[ "$DOCKER_COMMAND" == "docker compose" ]]; then
    $DOCKER_COMMAND version
else
    $DOCKER_COMMAND --version
fi

echo ""

if [ ! -f $DOCKER_ENV ]; then
  touch $DOCKER_ENV
fi

if ! grep -q "^USER_ID=" $DOCKER_ENV 2>/dev/null || ! grep -q "^GROUP_ID=" $DOCKER_ENV 2>/dev/null
then
    LUID="USER_ID=`id -u $USER`"
    [ "$LUID" == "USER_ID=0" ] && LUID="USER_ID=65534"
    LGID="GROUP_ID=`id -g $USER`"
    [ "$LGID" == "GROUP_ID=0" ] && LGID="GROUP_ID=65534"
    echo $LUID >> $DOCKER_ENV
    echo $LGID >> $DOCKER_ENV
fi


function crateDockerComposeVolumes() {
    createDir "app"
    createDir "app/bearpass"
    createDir "database"
    createDir "logs"
    createDir "logs/nginx"
    createDir "letsencrypt"
}

function createDir() {
    if [ ! -d "${OUTPUT_DIR}/$1" ]; then
        echo "Creating directory $OUTPUT_DIR/$1"
        mkdir -p $OUTPUT_DIR/$1
    fi
}

function initDockerCompose() {
    cp -n $DIR/docker-compose.override.yml.example $DIR/docker-compose.override.yml
}

function dockerComposeFiles() {
    if [ -f "$DIR/docker-compose.override.yml" ]; then
        export COMPOSE_FILE="$DIR/docker-compose.yml:$DIR/docker-compose.override.yml"
    else
        export COMPOSE_FILE="$DIR/docker-compose.yml"
    fi
    export COMPOSE_HTTP_TIMEOUT="300"
}

function dockerComposeDown() {
    dockerComposeFiles
    if [ $($DOCKER_COMMAND ps | wc -l) -gt 2 ]; then
        $DOCKER_COMMAND down
    fi
}

function dockerComposeUp() {
    dockerComposeFiles
    crateDockerComposeVolumes
    $DOCKER_COMMAND up -d --build
}


function install() {
    DATABASE_PASSWORD="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20 ; echo '')"

    echo "POSTGRES_PASSWORD=$DATABASE_PASSWORD" >> $DOCKER_ENV

    NGINX_CONF="$DIR/nginx/conf/conf.d/app.conf"

    if [ ! -f NGINX_CONF ]; then
        cp "$DIR/nginx/conf/conf.d/app.conf.example" $NGINX_CONF
    fi

    read -p "$(echo -e $YELLOW"\nEnter the url where the password manager will be located (without http/https):\n"$RESET_COLOR)`echo 'Like: bearpass.mysite.com'` `echo $'\n> '`" BEARPASS_URL

    if [ "$BEARPASS_URL" == "" ]; then
        BEARPASS_URL="localhost"
    fi

    PROTOCOL="http"

    if [ "$BEARPASS_URL" != "localhost" ]; then
        read -p "$(echo -e $YELLOW"\nWant to install a Let's Encrypt SSL certificate for Bearpass? (y/n)"$RESET_COLOR) `echo $'\n> '`" LETS_ENCRYPT

        if [ "$LETS_ENCRYPT" == "y" ] || [ "$LETS_ENCRYPT" == "yes" ]; then
            PROTOCOL="https"

            rm $NGINX_CONF && cp "$DIR/nginx/conf/conf.d/app-ssl.conf.example" $NGINX_CONF

            read -p "$(echo -e $YELLOW"\nEnter your email address (Let's Encrypt will use this for certificate expiration reminders)"$RESET_COLOR) `echo $'\n> '`" EMAIL

            openssl dhparam -out $OUTPUT_DIR/letsencrypt/ssl-dhparams.pem 2048 &&\

            docker pull certbot/certbot && \
            docker run -it --rm --name certbot -p 80:80 -v $OUTPUT_DIR/letsencrypt:/etc/letsencrypt/ certbot/certbot \
                certonly --standalone --noninteractive  --agree-tos --preferred-challenges http \
                --email $EMAIL -d $BEARPASS_URL --logs-dir /etc/letsencrypt/logs

        fi
    fi

    sed -i '' -e "s|BEARPASS_SITE_URL|$BEARPASS_URL|g" $NGINX_CONF

    APP_ENV_START="$DIR/app/conf/.env.start"

    if [ -f "$APP_ENV_START" ] ; then
        rm "$APP_ENV_START"
    fi

    touch $APP_ENV_START &&
    echo "DB_HOST=bearpass_database" >> $APP_ENV_START &&
    echo "APP_URL=$PROTOCOL://$BEARPASS_URL" >> $APP_ENV_START &&
    echo "DB_PASSWORD=$DATABASE_PASSWORD" >> $APP_ENV_START &&

    $DOCKER_COMMAND up -d --build
}

case $1 in
    "install")
        initDockerCompose && \
        crateDockerComposeVolumes && \
        dockerComposeFiles && \
        install
        ;;
    "restart")
        dockerComposeDown && \
        dockerComposeUp
        ;;
    "stop")
        dockerComposeDown
        ;;
esac