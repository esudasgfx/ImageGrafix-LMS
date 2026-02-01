#!/bin/bash
set -e

echo "Starting MySQL..."
service mariadb start

# Wait for MySQL
echo "Waiting for MySQL to be ready..."
sleep 10

# Initialize database
echo "Initializing database..."
mysql -uroot <<-EOSQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';
    CREATE DATABASE IF NOT EXISTS imagegrafix_lms;
    CREATE USER IF NOT EXISTS 'imagegrafix'@'%' IDENTIFIED BY 'password';
    GRANT ALL PRIVILEGES ON imagegrafix_lms.* TO 'imagegrafix'@'%';
    FLUSH PRIVILEGES;
EOSQL

echo "Starting Apache..."
exec apache2-foreground