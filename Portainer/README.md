
# Docker Compose File for Portainer

This Docker Compose file will set up Portainer, a lightweight management UI that allows you to easily manage your Docker environment.

## Prerequisites

- **Docker and Docker Compose Installed**: Ensure Docker and Docker Compose are installed on your system.

## Docker Compose File

Save the following content to a file named `docker-compose.yml`:

```yaml
services:
  portainer:
    image: portainer/portainer-ee:latest
    container_name: portainer
    restart: always
    ports:
      - "8000:8000"
      - "9000:9000"  # This port is for HTTP access to the Portainer web interface
      # Uncomment the following line to use HTTPS access instead of HTTP
      # - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
      # Uncomment the following lines to enable SSL certificate configuration
      # - /path/to/certificate.crt:/certs/cert.crt
      # - /path/to/private.key:/certs/cert.key
    environment:
      # Uncomment the following lines to configure Portainer for SSL
      # - "HTTPS_ENABLED=true"
      # - "SSL_CERT=/certs/cert.crt"
      # - "SSL_KEY=/certs/cert.key"

volumes:
  portainer_data:
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

## Optional: Enable HTTPS Support

To enable HTTPS support, follow these additional steps:

1. **Generate SSL Certificates**

   You can use Let's Encrypt to generate free SSL certificates or create self-signed certificates. Here's an example of generating self-signed certificates:

   ```bash
   mkdir -p /path/to/certs
   openssl req -x509 -newkey rsa:4096 -keyout /path/to/certs/private.key -out /path/to/certs/certificate.crt -days 365 -nodes
   ```

   Replace `/path/to/certs` with the actual path where you want to store your certificates.

2. **Update Docker Compose File for HTTPS**

   Uncomment the following lines in the `docker-compose.yml` file to enable SSL certificate configuration:

   ```yaml
    ports:
      - "8000:8000"
      - "9443:9443"  # Uncommented to enable HTTPS access
      # - "9000:9000"  # Comment out to disable HTTP access

    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
      - /path/to/certificate.crt:/certs/cert.crt
      - /path/to/private.key:/certs/cert.key

    environment:
      - "HTTPS_ENABLED=true"
      - "SSL_CERT=/certs/cert.crt"
      - "SSL_KEY=/certs/cert.key"
   ```

   Ensure that the paths to the certificate and key files match where you stored your generated certificates.

3. **Run Docker Compose Again**

   After updating the `docker-compose.yml` file, run the following command to apply the changes:

   ```bash
   docker-compose up -d
   ```

4. **Access Portainer Web Interface via HTTPS**

   Open a web browser and go to `https://localhost:9443` to access the Portainer web interface securely. If you are running Docker on a remote server, replace `localhost` with the server's IP address.

## Conclusion

By following these steps, you will have Portainer up and running, providing you with an easy-to-use interface to manage your Docker containers and environments. You also have the option to enable HTTPS for secure access to the Portainer web interface.