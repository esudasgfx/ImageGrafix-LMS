#!/bin/bash
set -e

echo "========================================"
echo "STARTING IMAGEGRAFIX LMS DEPLOYMENT"
echo "========================================"

echo "Step 1: Starting MySQL service..."
if service mariadb start; then
    echo "✓ MySQL service started"
else
    echo "WARNING: MySQL service start returned error, but continuing..."
fi

echo "Step 2: Waiting for MySQL to be ready..."
sleep 5

# Check if MySQL is running
if mysqladmin ping -hlocalhost --silent 2>/dev/null; then
    echo "✓ MySQL is running"
else
    echo "Starting MySQL manually..."
    mysqld_safe &
    sleep 10
fi

echo "Step 3: Initializing database..."
mysql -uroot <<EOSQL
    -- Set root password
    UPDATE mysql.user SET plugin='mysql_native_password' WHERE User='root';
    SET PASSWORD FOR 'root'@'localhost' = PASSWORD('password');
    
    -- Create database
    CREATE DATABASE IF NOT EXISTS imagegrafix_lms;
    
    -- Create user
    CREATE USER IF NOT EXISTS 'imagegrafix'@'%' IDENTIFIED BY 'password';
    
    -- Grant privileges
    GRANT ALL PRIVILEGES ON imagegrafix_lms.* TO 'imagegrafix'@'%';
    
    FLUSH PRIVILEGES;
EOSQL

echo "✓ Database initialized"

echo "Step 4: Starting Apache web server..."
echo "========================================"
echo "ImageGrafix LMS is ready!"
echo "========================================"

exec apache2-foreground
