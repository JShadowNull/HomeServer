#!/bin/bash

# Prompt the user for the location of the tar file to restore
read -p "Enter the full path to the tar file you want to restore (e.g., /path/to/backup/backup.tar): " BACKUP_FILE

# Check if the backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found at the specified location."
  exit 1
fi

# Prompt the user for the name of the new container
read -p "Enter the name for the new container: " NEW_CONTAINER_NAME

# Load the Docker image from the backup tar file
docker load -i $BACKUP_FILE

# Check if the image load was successful
if [ $? -eq 0 ]; then
  echo "Docker image loaded successfully from $BACKUP_FILE."
else
  echo "Failed to load the Docker image from the backup file."
  exit 1
fi

# Create a new container from the loaded image
docker run -d --name $NEW_CONTAINER_NAME <IMAGE_NAME>

# Check if the new container was created successfully
if [ $? -eq 0 ]; then
  echo "New container '$NEW_CONTAINER_NAME' created from the loaded image."
else
  echo "Failed to create the new container."
  exit 1
fi
