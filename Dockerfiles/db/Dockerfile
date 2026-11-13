FROM mysql:8.0.33

ENV MYSQL_DATABASE="accounts"
ENV MYSQL_ROOT_PASSWORD="admin123"

COPY /src/main/resources/db_backup.sql /docker-entrypoint-initdb.d/db_backup.sql

EXPOSE 3306