#!/bin/bash
# Database credentials
 user="rackuser"
 password="<RACKPASSWORD>"
 host="127.0.0.1"
 db_name="racktables"
 html_folder="/var/www/html/"

# Other settings
 max_age=14
 backup_path="racktables_backups"
 date=$(date +"%Y%m%d%H%M%S")

# Set default file permissions
 umask 133
# Dump database into SQL file
 mysqldump --user=$user -p$password $db_name > /$backup_path/$db_name-$date.sql

# Compress the file
cd /$backup_path
tar -czvf /$backup_path/$db_name-$date.tar.gz $db_name-$date.sql $html_folder

# Clean up
rm -f /$backup_path/$db_name-$date.sql
find /$backup_path/$db_name-*.tar.gz -mtime +$max_age -exec rm {} \;

# Optional : Upload to S3
s3cmd put /$backup_path/$db_name-$date.tar.gz s3://<RACKBUCKET>/
