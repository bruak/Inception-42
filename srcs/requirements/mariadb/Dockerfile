FROM debian:bullseye

RUN apt-get update && apt-get upgrade -y && apt-get install -y mariadb-server

COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY ./tools/setup-mysql.sh /

RUN chmod +x /setup-mysql.sh
ENTRYPOINT [ "/setup-mysql.sh" ]
CMD [ "mariadbd" ]