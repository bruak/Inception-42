FROM debian:bullseye

RUN apt -y update && apt -y upgrade \
	&& apt -y install nginx openssl 

COPY ./conf/https.conf /etc/nginx/conf.d/

COPY ./tools/nginx_start.sh /
RUN chmod +x /nginx_start.sh
ENTRYPOINT	[ "/nginx_start.sh" ]
CMD [ "nginx", "-g", "daemon off;" ]
