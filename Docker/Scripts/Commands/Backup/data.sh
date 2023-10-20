#!/bin/bash

# Prompt the user for the container name
read -p "Enter the name of the Docker container you want to back up: " CONTAINER_NAME

# Prompt the user for the location to save the backup
read -p "Enter the location to save the backup (e.g., /path/to/save/backup/): " BACKUP_LOCATION

# Prompt the user for the name of the tar file without the ".tar" extension
read -p "Enter the name of the tar file for the backup (e.g., my_backup): " TAR_FILENAME

# Add the ".tar" extension to the filename
TAR_FILENAME="$TAR_FILENAME.tar"

# Use docker run to create a tarball backup from the container's volumes
docker run --rm --volumes-from $CONTAINER_NAME -v $BACKUP_LOCATION:/backup busybox tar cvfz /backup/$TAR_FILENAME /containerpath

# Check if the backup was successful
if [ $? -eq 0 ]; then
  echo "Backup completed successfully. The tar file has been saved to $BACKUP_LOCATION/$TAR_FILENAME"
else
  echo "Failed to create the backup."
  exit 1
fi
