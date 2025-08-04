# HOW TO INSTALL ADMINER FOR DATABASE ADMINISTRATION GUI
**Table of Contents:**
+ [Guide](#guide)
	+ [STEP 1](#step-1)
	+ [STEP 2](#step-2)
	+ [STEP 3](#step-3)
	+ [STEP 4](#step-4)
	+ [STEP 5](#step-5-optional)

## GUIDE

### STEP 1:
Allow ports in UFW firewall:

    sudo ufw allow 8082/tcp # We will use the port 8082 for Adminer.
    sudo ufw reload

### STEP 2:
Install Adminer:

    sudo mkdir /var/www/adminer
    sudo wget https://www.adminer.org/latest.php -O /var/www/adminer/index.php

### STEP 3:
Configure Nginx web server:

For the web server configuration, we only provide configuration files for Nginx in http and https variants since Nginx is used in the main stack for Nextcloud.

    git clone https://github.com/JMarcosHP/Nextcloud-Guide.git
    sudo cp -r ~/Nextcloud-Guide/nextconf/nginx/adminer-http.conf /etc/nginx/sites-available # Or adminer-https.conf
    sudo ln -s /etc/nginx/sites-available/adminer-http.conf /etc/nginx/sites-enabled
    sudo nginx -t
    sudo systemctl reload nginx

### STEP 4:
Test Adminer:

Open a web browser and go to http://[LXC_EXTERNAL_IP]:8082

Select PostgreSQL and set the credentials for Nextcloud database or OnlyOffice database.

<img width="558" height="296" alt="Captura desde 2025-08-03 15-16-37" src="https://github.com/user-attachments/assets/ef4bacb6-e5d7-4c41-8ce0-b3c79b4bab5c" />
<img width="558" height="296" alt="Captura desde 2025-08-03 15-15-31" src="https://github.com/user-attachments/assets/2e997d28-1fdf-49f1-b111-adab5e1dc46a" />


### STEP 5 (Optional):
How to upgrade Adminer to a new version:

Simply redownload the `.php` index file from Adminer's website, reload Nginx and PHP-FPM.

    sudo wget https://www.adminer.org/latest.php -O /var/www/adminer/index.php
    sudo systemctl reload nginx phpX.Y-fpm
