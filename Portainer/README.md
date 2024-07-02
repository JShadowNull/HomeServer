
# Docker Compose File for Portainer

This Docker Compose file will set up Portainer, a lightweight management UI that allows you to easily manage your Docker environment.

## Prerequisites

- **Docker and Docker Compose Installed**: Ensure Docker and Docker Compose are installed on your system.

## Docker Compose File

Save the following content to a file named `docker-compose.yml`:

```yaml
version: '3'

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    ports:
      - 9000:9000  # Access Portainer web interface on port 9000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # Connect to the Docker socket for managing containers
    restart: always  # Restart the container automatically on failure
```

## Steps to Deploy Portainer

1. **Create the Docker Compose File**

   Save the Docker Compose file content shown above into a file named `docker-compose.yml`.

2. **Run Docker Compose**

   Navigate to the directory containing the `docker-compose.yml` file and run the following command to start the Portainer service:

   ```bash
   docker-compose up -d
   ```

   The `-d` flag runs the containers in detached mode.

3. **Access Portainer Web Interface**

   Open a web browser and go to `http://localhost:9000` to access the Portainer web interface. If you are running Docker on a remote server, replace `localhost` with the server's IP address.

4. **Initial Setup**

   Follow the on-screen instructions to complete the initial setup of Portainer. You will be prompted to create an admin user and connect Portainer to your Docker environment.

## Conclusion

By following these steps, you will have Portainer up and running, providing you with an easy-to-use interface to manage your Docker containers and environments.