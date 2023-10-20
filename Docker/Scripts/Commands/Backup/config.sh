#!/bin/bash

# Prompt the user for the container ID
read -p "Enter the Container ID you want to back up: " CONTAINER_ID

# Prompt the user for the backup file name
read -p "Enter the name of the backup file: " BACKUP_NAME

# Use docker commit to create a backup image from the running container
docker commit -p $CONTAINER_ID $BACKUP_NAME

# Check if the commit was successful
if [ $? -eq 0 ]; then
  echo "Backup image created successfully."
else
  echo "Failed to create a backup image."
  exit 1
fi

# Save the backup image as a tar file on the local machine
docker save -o ~/$BACKUP_NAME.tar $BACKUP_NAME

# Check if the tar file was saved successfully
if [ $? -eq 0 ]; then
  echo "Backup image saved as $BACKUP_NAME.tar in your home directory."
else
  echo "Failed to save the backup image as a tar file."
fi

# Optionally, list the contents of the home directory to confirm the backup file
ls -l ~/$BACKUP_NAME.tar
