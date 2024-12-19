#!/bin/bash

CYAN='\033[36m'
GREEN='\033[32m'
RED='\033[31m'
BLUE='\033[34m'
RESET='\033[0m'

sleep 2

if [ -f /run/secrets/db_password ]; then
    export MYSQL_PASSWORD=$(cat /run/secrets/db_password)
else
    echo -e "${RED}db_password secret file not found, password not set.${RESET}"
fi

if [ -f /run/secrets/db_root_password ]; then
    export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
else
    echo -e "${RED}db_root_password secret file not found, root password not set.${RESET}"
fi

if [ -f /run/secrets/credentials ]; then
    export MYSQL_USER=$(grep MYSQL_USER /run/secrets/credentials | cut -d '=' -f2 | tr -d '[:space:]')
    export MYSQL_DATABASE=$(grep MYSQL_DATABASE /run/secrets/credentials | cut -d '=' -f2 | tr -d '[:space:]')
else
    echo -e "${RED}credentials secret file not found, user and database not set.${RESET}"
fi

if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
    echo -e "${RED}Error: Some critical environment variables are not set.${RESET}"
    exit 1
fi


##############################################
# *sleep 5 is for waiting for the database to start.
##############################################

service mariadb start

sleep 5 

echo -e "Setting root password${RESET}..." && \
mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"

echo -e "Setting database [${BLUE}$MYSQL_DATABASE]${RESET}..." && \
mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;"

echo -e "Setting mysql user [${BLUE}$MYSQL_USER]${RESET}..." && \
mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"

echo -e "Giving permissions to database to user [${BLUE}$MYSQL_DATABASE]${RESET}..." && \
mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';"

echo -e "Flushing privileges to apply changes${RESET}..." && \
mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

echo -e "Database settings done, shutting down database${RESET}..." && \
mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHUTDOWN;"

echo -e "${GREEN}mariaDB ready!${RESET}"

exec "$@"   