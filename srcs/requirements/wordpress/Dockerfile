FROM debian:bullseye

RUN apt-get update && apt-get install -y php-fpm php-mysql wget
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp-cli
RUN mkdir -p /var/www/html

COPY ./conf/www.conf /etc/php/7.4/fpm/pool.d/

COPY ./tools /
RUN chmod +x /wordpress-start.sh
WORKDIR /var/www/html
ENTRYPOINT [ "/wordpress-start.sh" ]
CMD ["/usr/sbin/php-fpm7.4", "--nodaemonize"]
