#!/bin/bash

# Script để backup MySQL databases
# Sử dụng sau khi đã cài đặt MySQL với Ansible

BACKUP_DIR="/var/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
MYSQL_USER="root"
MYSQL_PASSWORD="{{ mysql_root_password }}"
RETENTION_DAYS=7

# Tạo thư mục backup nếu chưa có
mkdir -p $BACKUP_DIR

# Function to backup all databases
backup_all_databases() {
    echo "Starting MySQL backup at $(date)"
    
    # Backup all databases
    mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD --all-databases --single-transaction --routines --triggers > $BACKUP_DIR/all-databases-$DATE.sql
    
    if [ $? -eq 0 ]; then
        echo "Backup completed successfully: all-databases-$DATE.sql"
        
        # Compress backup
        gzip $BACKUP_DIR/all-databases-$DATE.sql
        echo "Backup compressed: all-databases-$DATE.sql.gz"
    else
        echo "Backup failed!"
        exit 1
    fi
}

# Function to backup individual databases
backup_individual_databases() {
    # Get list of databases
    DATABASES=$(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")
    
    for db in $DATABASES; do
        echo "Backing up database: $db"
        mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD --single-transaction --routines --triggers $db > $BACKUP_DIR/${db}-$DATE.sql
        
        if [ $? -eq 0 ]; then
            gzip $BACKUP_DIR/${db}-$DATE.sql
            echo "Database $db backed up successfully"
        else
            echo "Failed to backup database: $db"
        fi
    done
}

# Function to cleanup old backups
cleanup_old_backups() {
    echo "Cleaning up backups older than $RETENTION_DAYS days"
    find $BACKUP_DIR -name "*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete
    echo "Old backups cleaned up"
}

# Main execution
echo "MySQL Backup Script Started"
echo "Backup Directory: $BACKUP_DIR"
echo "Date: $DATE"
echo "Retention: $RETENTION_DAYS days"
echo "================================"

# Backup all databases
backup_all_databases

# Backup individual databases (optional)
# backup_individual_databases

# Cleanup old backups
cleanup_old_backups

echo "================================"
echo "MySQL backup script completed at $(date)"

# Show backup size
echo "Current backup directory size:"
du -sh $BACKUP_DIR
