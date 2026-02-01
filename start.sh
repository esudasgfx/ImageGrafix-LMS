#!/bin/bash
set -e

echo "========================================"
echo "STARTING IMAGEGRAFIX LMS DEPLOYMENT"
echo "========================================"

echo "Step 1: Starting MySQL service..."
service mariadb start || {
    echo "ERROR: Failed to start MySQL service"
    exit 1
}

echo "Step 2: Waiting for MySQL to be ready..."
# Wait longer and check if MySQL is actually running
for i in {1..30}; do
    if mysqladmin ping -hlocalhost --silent; then
        echo "✓ MySQL is running and ready"
        break
    fi
    echo "Waiting for MySQL... ($i/30)"
    sleep 2
done

# Final check
if ! mysqladmin ping -hlocalhost --silent; then
    echo "ERROR: MySQL failed to start after 60 seconds"
    exit 1
fi

echo "Step 3: Initializing database..."
# Use a safer MySQL initialization script
mysql -uroot <<-EOSQL
    -- Set root password (only if not already set)
    UPDATE mysql.user SET plugin='mysql_native_password' WHERE User='root';
    ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';
    
    -- Remove anonymous users
    DELETE FROM mysql.user WHERE User='';
    
    -- Remove remote root
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    
    -- Remove test database
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    
    -- Create our database
    CREATE DATABASE IF NOT EXISTS imagegrafix_lms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    
    -- Create application user
    CREATE USER IF NOT EXISTS 'imagegrafix'@'localhost' IDENTIFIED BY 'password';
    CREATE USER IF NOT EXISTS 'imagegrafix'@'%' IDENTIFIED BY 'password';
    
    -- Grant privileges
    GRANT ALL PRIVILEGES ON imagegrafix_lms.* TO 'imagegrafix'@'localhost';
    GRANT ALL PRIVILEGES ON imagegrafix_lms.* TO 'imagegrafix'@'%';
    
    -- Apply changes
    FLUSH PRIVILEGES;
    
    -- Show databases for verification
    SHOW DATABASES;
EOSQL

if [ $? -eq 0 ]; then
    echo "✓ Database initialized successfully"
else
    echo "ERROR: Database initialization failed"
    exit 1
fi

echo "Step 4: Starting Apache web server..."
echo "========================================"
echo "ImageGrafix LMS is starting..."
echo "========================================"

# Start Apache in foreground
exec apache2-foreground
