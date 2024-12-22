#!/bin/bash

CYAN='\033[36m'
GREEN='\033[32m'
RED='\033[31m'
BLUE='\033[34m'
YELLOW='\033[33m'
RESET='\033[0m'

##############################################
# sleep 10 is for waiting the database to be ready
##############################################

sleep 10

chown -R www-data: /var/www/*
chmod -R 755 /var/www/*
mkdir -p /run/php/
touch /run/php/php7.4-fpm.pid
chown -R www-data:www-data /var/www/html/

if [ -f /run/secrets/credentials ]; then
	export MYSQL_DATABASE=$(grep MYSQL_DATABASE /run/secrets/credentials | cut -d '=' -f2 | tr -d '[:space:]')
	export MYSQL_USER=$(grep MYSQL_USER /run/secrets/credentials | cut -d '=' -f2 | tr -d '[:space:]')
	export WP_ADMIN_LOGIN=$(grep WP_ADMIN_LOGIN /run/secrets/credentials | cut -d '=' -f2 | tr -d '[:space:]')
	export WP_ADMIN_EMAIL=$(grep WP_ADMIN_EMAIL /run/secrets/credentials | cut -d '=' -f2 | tr -d '[:space:]')
	export WP_USER_EMAIL=$(grep WP_USER_EMAIL /run/secrets/credentials | cut -d '=' -f2 | tr -d '[:space:]')
	export MAIL_EXTENTION=$(grep MAIL_EXTENTION /run/secrets/credentials | cut -d '=' -f2 | tr -d '[:space:]')
fi

if [ -f /run/secrets/db_password ]; then
	export MYSQL_PASSWORD=$(cat /run/secrets/db_password)
fi

if [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ] || \
	 [ -z "$WP_ADMIN_LOGIN" ] || [ -z "$WP_ADMIN_EMAIL" ] || [ -z "$WP_USER_EMAIL" ] || [ -z "$MAIL_EXTENTION" ]; then
	echo -e "${RED}Error: Some critical environment variables are not set.${RESET}"
	exit 1
fi

echo -e "MYSQL_USER: ${BLUE}[$MYSQL_USER]${RESET}"
echo -e "MYSQL_DATABASE: ${BLUE}[$MYSQL_DATABASE]${RESET}"
echo -e "MYSQL_PASSWORD: ${BLUE}[$MYSQL_PASSWORD]${RESET}"
echo -e "WP_ADMIN_LOGIN: ${BLUE}[$WP_ADMIN_LOGIN]${RESET}"
echo -e "WP_ADMIN_EMAIL: ${BLUE}[$WP_ADMIN_EMAIL]${RESET}"
echo -e "WP_USER_EMAIL: ${BLUE}[$WP_USER_EMAIL]${RESET}"
echo -e "MAIL_EXTENTION: ${BLUE}[$MAIL_EXTENTION]${RESET}"


if [ ! -f /var/www/html/wp-config.php ]; then

max_attempts=10
attempt=1
	until wp-cli core download --allow-root; do
	    if [ $attempt -ge $max_attempts ]; then
	        echo -e "${RED}Core download failed, reached maximum attempts, max attempts: $max_attempts${RESET}"
	        exit 1
	    fi
	    echo -e "${YELLOW}Core download failed, retrying in 2 seconds... (Attempt: $attempt/${max_attempts})${RESET}"
	    attempt=$(( $attempt + 1 ))
	    sleep 2
	done

attempt=1
	until wp-cli config create --allow-root \
	    --dbname=$MYSQL_DATABASE \
	    --dbuser=$MYSQL_USER \
	    --dbpass=$MYSQL_PASSWORD \
	    --dbhost=mariadb; do
	    if [ $attempt -ge $max_attempts ]; then
	        echo -e "${RED}Database configuration failed, reached maximum attempts. Max attempts: $max_attempts${RESET}"
	        exit 1
	    fi
	    echo -e "${YELLOW}Database connection failed, retrying in 2 seconds... (Attempt: $attempt/${max_attempts})${RESET}"
	    attempt=$((attempt + 1))
	    sleep 2
	done

attempt=1
	until wp-cli core install --allow-root \
	    --url=$DOMAIN_NAME \
	    --title="wordpress" \
	    --admin_user=$WP_ADMIN_LOGIN \
	    --admin_password=$MYSQL_PASSWORD \
	    --admin_email=$WP_ADMIN_EMAIL; do
	    if [ $attempt -ge $max_attempts ]; then
	        echo -e "${RED}Core installation failed, reached maximum attempts. Max attempts: $max_attempts${RESET}"
	        exit 1
	    fi
	    echo -e "${YELLOW}Core installation failed, retrying in 2 seconds... (Attempt: $attempt/${max_attempts})${RESET}"
	    attempt=$((attempt + 1))
	    sleep 2
	done

attempt=1
	until wp-cli user create --allow-root \
	    $MYSQL_USER $MAIL_EXTENTION \
	    --user_pass=$MYSQL_PASSWORD; do
	    if [ $attempt -ge $max_attempts ]; then
	        echo -e "${RED}User creation failed, reached maximum attempts. Max attempts: $max_attempts${RESET}"
	        exit 1
	    fi
	    echo -e "${YELLOW}User creation failed, retrying in 2 seconds... (Attempt: $attempt/${max_attempts})${RESET}"
	    attempt=$((attempt + 1))
	    sleep 2
	done
	
	wp-cli user list --allow-root | while IFS= read -r line; do
		echo -e "${BLUE}$line${RESET}"
	done

	echo -e "${GREEN}WordPress installation completed successfully.${RESET}"
else 
	echo -e "${GREEN}WordPress is already installed.${RESET}"
fi



exec "$@"
