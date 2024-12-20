#!/bin/bash

CYAN='\033[36m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
RESET='\033[0m'

if [ -f /run/secrets/credentials ]; then
    export SUBJ=$(grep SUBJ /run/secrets/credentials | awk -F '=' '{sub(/^ +| +$/, "", $2); print substr($0, index($0, $2))}')
	export CRT=$(grep -E '^CRT=' /run/secrets/credentials | cut -d '=' -f2 | tr -d '[:space:]')
	export CRT_KEY=$(grep -E '^CRT_KEY=' /run/secrets/credentials | cut -d '=' -f2 | tr -d '[:space:]')	
else
    echo -e "${RED}Credentials secret file not found, didn't get information for SSL.${RESET}"
fi

if [ -z "$SUBJ" ] || [ -z "$CRT" ] || [ -z "$CRT_KEY" ]; then
	echo -e "${RED}Error: SSL informations are not set in secret file, check the credentials file or parse algorithm.${RESET}"
	exit 1
fi


if [ ! -f $CRT ]; then
    openssl req -x509 -sha256 -nodes \
	-newkey rsa:4096 \
	-days 365 \
	-subj "$SUBJ" \
	-keyout $CRT_KEY \
	-out $CRT
else
	echo -e "${YELLOW}Certificate already exists, skipping...${RESET}"
fi

sed -i "s|!CERTIFICATE_KEY_LOCATION!|${CRT_KEY}|g" \
	/etc/nginx/conf.d/https.conf
sed -i "s|!CERTIFICATE_LOCATION!|${CRT}|g" \
	/etc/nginx/conf.d/https.conf

echo -e "${GREEN}success SSL settings done, starting nginx...${RESET}"

exec "$@"

