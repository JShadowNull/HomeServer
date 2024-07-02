
# Setting Up Certbot Certificate Using Cloudflare DNS

This guide will walk you through the steps to obtain an SSL certificate using Certbot and Cloudflare DNS. This is useful for automating the certificate issuance and renewal process.

## Prerequisites

1. **Domain Name**: Ensure you have a domain name registered and managed through Cloudflare.
2. **Cloudflare Account**: You must have an active Cloudflare account with the domain properly configured.
3. **Certbot Installed**: Certbot must be installed on your server. You can install it using the following commands:
    ```bash
    sudo apt update
    sudo apt install certbot
    ```

## Step-by-Step Guide

### 1. Install Certbot DNS Cloudflare Plugin

To use Cloudflare DNS for domain verification, you need the Certbot Cloudflare plugin. Install it using `pip3`:
```bash
sudo apt install python3-pip
sudo pip3 install certbot-dns-cloudflare
```

### 2. Obtain Cloudflare API Token

You need a Cloudflare API token with DNS edit permissions:
1. Go to the Cloudflare dashboard.
2. Navigate to **My Profile** -> **API Tokens**.
3. Click on **Create Token**.
4. Use the **Edit zone DNS** template.
5. Set **Zone Resources** to include all zones or specific zones you need.
6. Generate the token and copy it. Keep it secure.

### 3. Create Cloudflare Configuration File

Create a configuration file to store your Cloudflare credentials. Store it in a secure location (e.g., `/etc/letsencrypt`).

Create the file `/etc/letsencrypt/cloudflare.ini`:
```ini
dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN
```

Change the file permissions to restrict access:
```bash
sudo chmod 600 /etc/letsencrypt/cloudflare.ini
```

### 4. Obtain SSL Certificate

Use Certbot with the Cloudflare plugin to obtain your certificate. Replace `example.com` with your domain:
```bash
sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  --dns-cloudflare-propagation-seconds 60 \
  -d example.com \
  -d *.example.com
```

The `--dns-cloudflare-propagation-seconds` option specifies the propagation time in seconds. Adjust this value as needed for your setup.

### 5. Automate Certificate Renewal

Certbot automatically adds a renewal entry in your crontab. However, you need to ensure it uses the Cloudflare plugin for DNS verification. Open the Certbot renewal configuration file (typically found at `/etc/letsencrypt/renewal/example.com.conf`) and add the following lines:
```ini
dns_cloudflare_credentials = /etc/letsencrypt/cloudflare.ini
dns_cloudflare_propagation_seconds = 60
```

Test the renewal process with:
```bash
sudo certbot renew --dry-run
```

Reload your web server to apply the changes.

### 6. Optional: Renew Certificates Manually

If needed, you can manually renew your certificates by running:
```bash
sudo certbot renew
```

### 7. Post-Script: Copy Certificates

To automate the process of copying the certificates to the desired directory, create a script named `copy_certs.sh`:

Create the file `copy_certs.sh` in the /etc/letsencrypt/renewal-hooks/post directory. This is necessary for Authentik to get Certbot certs in /certs directory:
```bash
#!/bin/bash

# Define variables
DOMAIN="example.com"
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
DEST_DIR="/path/to/destination"

# Copy the certificates
cp $CERT_DIR/fullchain.pem $DEST_DIR/fullchain.pem
cp $CERT_DIR/privkey.pem $DEST_DIR/privkey.pem
```

Make the script executable:
```bash
sudo chmod +x copy_certs.sh
```

### Authentik /certs Directory Layout

The layout for the Authentik `/certs` directory should be:

```
- certs
  - example.com
    - cert1
    - cert2
    - cert3
    - cert4
```