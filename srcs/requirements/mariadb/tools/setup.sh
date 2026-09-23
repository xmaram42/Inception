#!/bin/bash
set -e

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
	mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

if [ ! -f /var/lib/mysql/.initialized ]; then
	mysqld_safe --skip-networking --datadir=/var/lib/mysql &

	until mysqladmin ping --silent; do
		sleep 1
	done

	mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

	touch /var/lib/mysql/.initialized
	mysqladmin -u root -p"${DB_ROOT_PASSWORD}" shutdown
fi

exec mysqld --user=mysql --datadir=/var/lib/mysql
