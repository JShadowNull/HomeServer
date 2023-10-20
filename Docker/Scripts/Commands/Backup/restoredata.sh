#!/bin/bash

# Prompt the user for the location of the backup file to restore
read -p "Enter the full path to the backup file you want to restore (e.g., /path/to/restore/backup.tar): " BACKUP_FILE

# Check if the backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found at the specified location."
  exit 1
fi

# Prompt the user for the container name
read -p "Enter the name of the Docker container to restore the data into: " CONTAINER_NAME

# Prompt the user for the container path to restore the data into
read -p "Enter the container path to restore the data into (e.g., /containerpath): " CONTAINER_PATH

# Use docker run to restore data from the backup file into the container
docker run --rm --volumes-from $CONTAINER_NAME -v $BACKUP_FILE:/backup/backup.tar busybox sh -c "cd $CONTAINER_PATH && tar xvf /backup/backup.tar --strip 1"

# Check if the restore was successful
if [ $? -eq 0 ]; then
  echo "Data has been successfully restored into $CONTAINER_NAME at $CONTAINER_PATH"
else
  echo "Failed to restore data."
  exit 1
fi
