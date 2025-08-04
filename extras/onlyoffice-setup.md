# ONLYOFFICE DOCUMENT SERVER INSTALLATION

**Table of Contents:**
+ [Guide](#guide)
	+ [STEP 1](#step-1)
	+ [STEP 2](#step-2)
	+ [STEP 3](#step-3)
	+ [STEP 4](#step-4)
	+ [STEP 5](#step-5)
	+ [STEP 6](#step-6)
	+ [STEP 7](#step-7)
	+ [STEP 8](#step-8)
	+ [STEP 9](#step-9)

## GUIDE

### STEP 1:
Allow the necessary ports in UFW Firewall (See the port [list](https://test-helpcenter.onlyoffice.com/installation/docs-community-open-ports.aspx))

    sudo ufw allow 8081,5672,8000,25672,8126,4369,8080/tcp
    sudo ufw allow 8125/udp
    sudo ufw reload
### STEP 2:
Create onlyoffice database and user:

    sudo -i -u postgres psql -c "CREATE USER onlyoffice WITH PASSWORD 'changeme';"
    sudo -i -u postgres psql -c "CREATE DATABASE onlyoffice OWNER onlyoffice;"

### STEP 3:
Install the required dependencies:

    sudo apt install -y rabbitmq-server ttf-mscorefonts-installer

### STEP 4
Add OnlyOffice repository:

    curl -fsSL https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/onlyoffice.gpg
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main" | sudo tee /etc/apt/sources.list.d/onlyoffice.list
    sudo apt update

Configure debconf-selections for the server:

    echo onlyoffice-documentserver onlyoffice/ds-port select 8081 | sudo debconf-set-selections # We will use 8081 port for webui. (See OO port list).
    echo onlyoffice-documentserver onlyoffice/db-host string /var/run/postgresql | sudo debconf-set-selections
    echo onlyoffice-documentserver onlyoffice/db-user string onlyoffice | sudo debconf-set-selections
    echo onlyoffice-documentserver onlyoffice/db-pwd password #youronlyofficeuserpassword | sudo debconf-set-selections
    echo onlyoffice-documentserver onlyoffice/db-name string onlyoffice | sudo debconf-set-selections

Now install the server:

    sudo apt install -y onlyoffice-documentserver

### STEP 5
Add ds user to www-data group:

    sudo usermod -aG www-data ds

### STEP 6:
Add redis support to onlyoffice docs:
Edit `/etc/onlyoffice/documentserver/local.json` and add the following configuration after the sql key
([Source](https://redis.io/docs/latest/develop/clients/nodejs/connect/#connect-to-your-production-redis-with-tls))

    "redis": {
      "host": "/run/redis/redis-server.sock",
      "password": "//yourredispassword"
    },
  
Add ds user to redis group:

    sudo usermod -aG redis ds

Restart the server:

    sudo systemctl restart ds*

### STEP 7:

Start the example service:

    sudo systemctl start ds-example

Now let's test the Onlyoffice Docs server to see if everything is working:
In a browser go to: http://[LXC_EXTERNAL_IP]:8081

<img width="1873" height="954" alt="Captura desde 2025-07-31 19-46-29" src="https://github.com/user-attachments/assets/fbb99d0d-53ba-4dc8-a3e4-9f6882a46f54" />

You will see the welcome page, let's try the example and create some documents.

<img width="1873" height="997" alt="Captura desde 2025-07-31 19-46-56" src="https://github.com/user-attachments/assets/58959ce5-fd1f-4108-9edb-d2c8746b0e1a" />
<img width="1873" height="997" alt="Captura desde 2025-07-31 19-46-45" src="https://github.com/user-attachments/assets/3548d2cc-1957-46ea-bb98-e4b31bdc7a51" />

Once you tested the server, stop the ds-example service:

    sudo systemctl disable --now ds-example

### STEP 8:
Let's hide the welcome page:
Edit `/etc/nginx/includes/ds-docservice.conf` and comment the second line:

    #rewrite ^/$ $the_scheme://$the_host$the_prefix/welcome/ redirect;

Save the file and reload nginx:

    sudo systemctl reload nginx

Now if you enter again in http://[LXC_EXTERNAL_IP]:8081 it will not redirect to the welcome page, you have to manually type the /welcome path to access it.

### STEP 9:
Add OnlyOffice support to Nextcloud:
Install the OnlyOffice connector app.

    sudo -u www-data php -f /var/www/nextcloud/occ app:install onlyoffice

Then get your JWT access token with:

    sudo bash documentserver-jwt-status.sh
Copy your token and header string.

Now go to the Onlyoffice connector settings in Nextcloud and set the following configuration:

<img width="1080" height="764" alt="Captura desde 2025-07-31 19-52-08 (Editado)" src="https://github.com/user-attachments/assets/322a70cd-efe6-4080-a2cd-3a887750c1a9" />


For a local instance set the url like:

    http://[LXC_EXTERNAL_IP]:8081/ # Ex: 192.168.1.9

or

    https://[LXC_EXTERNAL_IP]:8081/ # In case you are running a selfsigned instance.

And paste your JWT token + Authorization header, then click Save.

**CONGRATULATIONS!** Your OnlyOffice Document Server is fully operational and integrated with Nextcloud.

If you want to configure the proxy for selfhosting, please check this [guide](https://github.com/JMarcosHP/Nextcloud-Guide/blob/main/extras/proxy-config.md#onlyoffice-document-server-configuration).
