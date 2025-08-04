# Proxmox Nextcloud baremetal installation guide in Debian LXC

**This guide covers how to install Nextcloud with the following stack:**
- Nginx 1.28 (stable branch)
- Latest Nextcloud Server stable
- PostgreSQL 17
- PHP-FPM 8.4
- APCu
- Memcached
- Redis 8

**Includes:**
- Nextcloud adjustements from AIO/Server tuning manual section.
- Memories app setup.
- PostgreSQL Database tuning acording to HW specs/Number of connections.
- PHP-FPM.ini & pool parameter tuning.
- Unix socket support for Database and Redis.
- GPU Passthrough to LXC for video transcoding support.
- Mount ZFS disk pool for additional space and Nextcloud data folder.
- Push notifications support.
- Automatic preview generation.

**Extras:**
- Selfhost/Proxy/HTTPS/SSL Support with [Nginx Proxy Manager LXC](https://community-scripts.github.io/ProxmoxVE/scripts?id=nginxproxymanager).
- OnlyOffice DocumentServer 9 (baremetal installation).
- How to install Adminer for database administration GUI.
- How to migrate to a newer PHP version.
- How to migrate to a newer PostgreSQL version.
- How to upgrade Debian to a newer release.
- How to make a LXC Snapshot Backup in Proxmox

**This guide assumes you have:**
- A working Proxmox node.
- At least 1 ZFS Pool or LVM disk to storage the LXC. (2 are recomended, 1 to save the LXC itself and 1 to store the nextcloud data).
- Intermediate Linux, Shell, Unix Permission Skills.
- For selfhosting, a proxy host, a fully working domain pointing to your public IP and a DDNS service, the 443 port forwarded in your router and pointing to the proxy host. (This guide only covers [Nginx Proxy Manager LXC](https://community-scripts.github.io/ProxmoxVE/scripts?id=nginxproxymanager) proxy host settings).
- At least 4GB Ram free, 4 cores, 64Gb free space for the LXC.
- Integrated or dedicated graphics card for video transcoding, otherwise, stick to ffmpeg and CPU transcoding. (Intel/AMD preferred, but you can install nvidia drivers).

**Table of Contents:**
 + [Guide](#guide)
	+ [Preparing the Storage](#preparing-the-storage)
	+ [Creating the LXC Container](#creating-the-lxc-container)
	+ [Container Setup](#container-setup)
	+ [Preparing the necessary stuff](#preparing-the-necessary-stuff)
	+ [Server Tunning](#server-tunning)
	+ [Configuring NGINX](#configuring-nginx)
	+ [Nextcloud Server Setup](#nextcloud-server-setup)
	+ [Begin the Nextcloud installation](#begin-the-nextcloud-installation)
	+ [Nextcloud post-installation adjustements](#nextcloud-post-installation-adjustements)
	+ [Adding Push Notifications support](#adding-push-notifications-support)
	+ [Setup automatic preview generation](#setup-automatic-preview-generation)
	+ [Memories app setup](#memories-app-setup)
+ [Extras](#extras)

## GUIDE

### Preparing the storage
For this guide we will use an unprivileged LXC, if you don't know how to handle the permissions and ownership, please read this explanation before starting.

In this case I'll use a ZFS dataset created on an existing pool.
To create one:

    zfs create disk2/ncdata

Now get the mountpoint of the dataset with:

    zfs get mountpoint disk2/ncdata

We need this path to mount it in the LXC later.

<br/><br/>

### CREATING THE LXC CONTAINER

First download the latest Debian standard template:

<img width="903" height="603" alt="image" src="https://github.com/user-attachments/assets/38140b95-58e8-4c6c-b2ba-0f7b8598e1cd" /><br/><br/><br/>

Now Lets Create the LXC:

<img width="727" height="544" alt="Captura desde 2025-07-30 17-03-25" src="https://github.com/user-attachments/assets/d00ad0f9-378b-41ee-9e8e-0c78cb1ddd82" />

Set a hostname, ID number and a password for the root user.<br/><br/><br/>

<img width="724" height="537" alt="Captura desde 2025-07-30 12-38-00" src="https://github.com/user-attachments/assets/15158549-cf80-443c-9c67-1978b402abe4" />

Select the Debian template from your storage.<br/><br/><br/>

<img width="724" height="537" alt="Captura desde 2025-07-30 12-37-52" src="https://github.com/user-attachments/assets/42bc5290-42e6-4ca3-8b87-7eba8daf743b" />

Choose the storage where the LXC will be saved, set 64GB for disk size, for mount options select: discard (only if your storage is SSD),noatime,lazytime.<br/><br/><br/>

<img width="724" height="537" alt="Captura desde 2025-07-30 12-39-11" src="https://github.com/user-attachments/assets/e52ca95b-f8b4-4f94-a6ca-85b43dbdc7d4" />

Set the desired amount of CPU cores, in this case I'll set it to 8.<br/><br/><br/>

<img width="724" height="537" alt="Captura desde 2025-07-30 12-39-16" src="https://github.com/user-attachments/assets/dbb339d4-fa66-4248-91e0-c73e17156fa9" />

Set at least 4GB of ram and 1GB for swap.<br/><br/><br/>

<img width="724" height="537" alt="Captura desde 2025-07-30 12-39-44" src="https://github.com/user-attachments/assets/26907634-c803-4d7c-a94e-220da2a503f5" />

For network, assign a static IPV4 address with its gateway. If your ISP provides a fully working IPv6 select SLAAC, if not, just leave it static.<br/><br/><br/>

<img width="724" height="537" alt="Captura desde 2025-07-30 12-41-37" src="https://github.com/user-attachments/assets/5580b9f0-ff75-4449-a68f-bba56b60bcd8" />

For DNS you can use the host settings, or another dns provider like `8.8.8.8,1.1.1.1`<br/><br/><br/>

<img width="724" height="537" alt="Captura desde 2025-07-30 12-41-41" src="https://github.com/user-attachments/assets/45bd3ca9-226d-42c3-9ae7-738a3c5e2945" />

Finish the container creation.<br/><br/><br/>

Now is the time to add the mountpoint for the Nextcloud data directory storage, go to your Proxmox shell and execute:

    zfs get mountpoint disk2/ncdata
    pct set 110 -mp0 /srv/nas/disk2/ncdata,mp=/mnt/ncdata
    # Adjust the container ID and mount path to yours.
    # You can bind mount another folders as needed.

Now set the ownership for data folder:

    chown -R 100033:100033 /srv/nas/disk2/ncdata
<br/><br/><br/>
**(OPTIONAL)** GPU Passthrough for video transcoding.

<img width="304" height="97" alt="Captura desde 2025-07-29 21-03-38" src="https://github.com/user-attachments/assets/11774560-9400-4034-b81d-c97d556f5829" />

Go to your Nextcloud container resources section and add a device passthrough.<br/><br/><br/>

In the Proxmox Shell get the card number with:

    ls /dev/dri
<br/><br/><br/>
<img width="457" height="201" alt="Captura desde 2025-07-30 12-16-00" src="https://github.com/user-attachments/assets/7fa82c38-58a3-4e3f-84b1-31ad57c2bf49" />

For the path: `/dev/dri/renderD128`, set `GID 104` (render group in Debian), access mode `0666`.<br/><br/><br/>

<img width="457" height="201" alt="Captura desde 2025-07-30 12-16-33" src="https://github.com/user-attachments/assets/bc0f4cb4-4e4d-46bb-86cb-e620be50dd4f" />

Add another device with the card number, set `GID 44` (video group), access mode `0666`.

With all of this, we are ready to Power ON and setup the Container.

<br/><br/>
### CONTAINER SETUP
First enter the container and setup your timezone and language locale:

    dpkg-reconfigure tzdata
    dpkg-reconfigure locales

Edit `/etc/apt/sources.list` and add "non-free" and "non-free-firmware" to the repositories:

    deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
    deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
    deb http://security.debian.org bookworm-security main contrib non-free non-free-firmware

Then apply pending updates:

    apt update && apt upgrade -y

Reboot the container:

    reboot

**(Optional but recommended)** Create a new sudo user for administrative tasks:

    apt install sudo
    useradd ncadmin -m -g users -s /bin/bash
    passwd ncadmin
    groupadd ncadmin -g 1000
    usermod -aG sudo ncadmin
    usermod -aG ncadmin ncadmin

Switch to the new user:

    su - ncadmin

Now we will use ncadmin for every command in this guide, or you can stick with the root user.

### Preparing the necessary stuff:

Install a firewall:

    sudo apt install ufw

Allow the required ports in ufw for this setup:

    sudo ufw enable
    sudo ufw allow 22,80,443,5432,6739,7867,9000/tcp
    sudo ufw allow 443/udp
    sudo ufw reload

In this guide we will use external repositories to facilitate upgrading versions of any part of the stack, but you can compile it from source or use the provided packages from the distribution.

Add Sury's(https://deb.sury.org/#debian-dpa) Nginx & PHP repositories, provided by an Official Debian Developer:

    sudo apt install -y lsb-release ca-certificates curl
    sudo curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
    sudo dpkg -i /tmp/debsuryorg-archive-keyring.deb
    sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/nginx/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/nginx.list'
    sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
    sudo apt update

Install Nginx packages:

    sudo apt install -y nginx nginx-extras

Install PostgreSQL packages:

    sudo apt install -y postgresql-common

Add the official PostgreSQL repository:

    sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh

Press enter and then install postgresql-17:

    sudo apt install postgresql-17 postgresql-client-17

Install PHP packages:

    sudo apt install -y php8.4-{fpm,pgsql,gd,curl,mbstring,xml,zip,intl,bcmath,gmp,imagick,redis,apcu,smbclient,ldap,imap} imagemagick librsvg2-bin libmagickcore-6.q16-6-extra

Add the Official Redis server repository:

    sudo apt install -y lsb-release curl gpg
    curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    sudo chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
    sudo apt update

Install Redis:

    sudo apt install -y redis

Other Packages:

    sudo apt install -y unzip zip wget curl vim ffmpeg git gnupg 7zip net-tools

Drivers for AMD GPUS:

    sudo apt install -y firmware-amd-graphics libgl1-mesa-dri libglx-mesa0 mesa-vulkan-drivers

Drivers for Intel GPUS:

    sudo apt install -y intel-media-va-driver-non-free i965-va-driver-shaders

Drivers for Nvidia GPUS:

    sudo apt install -y nvidia-driver nvidia-vaapi-driver

Enable and Start the necessary services:

    sudo systemctl enable --now nginx php8.4-fpm postgresql redis-server

### Server Tunning
**Database tunning and Unix socket configuration:**
Use the following page to get the appropiate configuration acording with your hardware specs. [https://pgtune.leopard.in.ua/](https://pgtune.leopard.in.ua/)

Now edit `/etc/postgresql/17/main/postgresql.conf` and set the values given by the page.
Then proceed editing this lines for the Unix socket:

    listen_addresses = '' # If you still need TCP connection leave it to listen_addresses = 'localhost'
    unix_socket_directories = '/var/run/postgresql'
    unix_socket_group = 'www-data'
    unix_socket_permissions = 0770

Save the file
And now add the postgres user to the www-data group:

    sudo usermod -aG www-data postgres

Edit `/etc/postgresql/17/main/pg_hba.conf` to enable access using unix socket like this:

    # "local" is for Unix domain socket connections only
    local   all             all                                     scram-sha-256
    # Allow replication connections from localhost, by a user with the
    # replication privilege.
    local   replication     all                                     scram-sha-256

Restart postgresql:

    sudo systemctl restart postgresql

**Redis tunning and Unix socket configuration:**
Edit and set the following configuration in `/etc/redis/redis.conf`

    port 0
    unixsocket /run/redis/redis-server.sock
    unixsocketperm 770
    maxclients 10240
    requirepass yourpassword # Set a strong password here

Add the www-data user to redis group:

    sudo usermod -aG redis www-data

Restart redis:

    sudo systemctl restart redis-server

**(Optional)** Add a cronjob to optimize redis:
Clone this repository and add a cronjob with the script:

    git clone https://github.com/JMarcosHP/Nextcloud-Guide
    sudo cp -r Nextcloud-Guide/nextconf /opt
    cd /opt/nextconf/

Edit `redis-optimization.sh` and set your redis password:

    redis-cli -s /run/redis/redis-server.sock -a 'yourredispassword'

Save the script and give exectution permissions.

    sudo chmod +x redis-optimization.sh

Add the cronjob:

    sudo crontab -e
    # Redis Optimization
    5 1 * * * /opt/nextconf/redis-optimization.sh

**PHP-FPM Tunning:**
Edit/Add if missing the recommended configuration for Nextcloud in `/etc/php/8.4/fpm/php.ini`

    output_buffering = off
    max_execution_time = 86400
    default_socket_timeout = 86400 # Always set the same value of max_execution_time
    memory_limit = 1024M # Adjust if you need more.
    post_max_size = 16G # Adjust if you need more.
    upload_max_filesize = 16G # Always set the same value of post_max_size
    session.save_handler = redis
    session.save_path = "unix:///run/redis/redis-server.sock?auth=yourredispassword&database=1" # Make sure your password doesn't contain "&" character as it's reserved to indicate the database index. 
    session.serialize_handler = igbinary
    redis.session.locking_enabled = 1
    redis.session.lock_retries = -1
    redis.session.lock_wait_time = 10000
    opcache.enable=1
    opcache.jit=1255
    opcache.jit_buffer_size=8M
    opcache.memory_consumption=256
    opcache.interned_strings_buffer=64
    opcache.max_accelerated_files=10000
    opcache.revalidate_freq=2
    opcache.save_comments=1
    apc.serializer = igbinary
    apc.shm_size = 128M

Execute the php-fpm-autocalculation to get the appropiate values for your hardware:

    cd /opt/nextconf
    sudo chmod +x php-fpm-autocalculation.sh
    ./php-fpm-autocalculation.sh

Then select an option and set the configuration to `/etc/php/8.4/fpm/pool.d/www.conf`
And uncomment this line:

    ;env[PATH] = /usr/local/bin:/usr/bin:/bin


Save the files and apply the configuration with:

    sudo systemctl restart php8.4-fpm

### Configuring NGINX:
I included in this repository a Nginx configuration file based in the Nextcloud manual and notify_push requirements, you can choose the http file or the https variant, for the https variant you can adapt it if you already have your own certificate, or read this [guide](https://github.com/JMarcosHP/Nextcloud-Guide/blob/main/extras/proxy-config.md#nextcloud-configuration) if you want to selfhost it using Nginx Proxy Manager later.

Disable Nginx welcome page:

    sudo rm /etc/nginx/sites-enabled/default


Copy the nginx file:

    sudo cp -r /opt/nextconf/nextcloud-http.conf /etc/nginx/sites-available

Or

    sudo cp -r /opt/nextconf/nextcloud-https.conf /etc/nginx/sites-available

For the https variant.

And add the symlink to sites-enabled:

    sudo ln -s /etc/nginx/sites-available/nextcloud-http.conf /etc/nginx/sites-enabled/

Or

    sudo ln -s /etc/nginx/sites-available/nextcloud-https.conf /etc/nginx/sites-enabled/

Check syntax and reload nginx:

    sudo nginx -t
    sudo systemctl reload nginx

### Nextcloud Server Setup:
Create the Nextcloud database and user:

*NOTE: Use your own strong password.*

    sudo -u postgres psql <<EOF
    CREATE DATABASE nextcloud TEMPLATE template0 ENCODING 'UTF-8';
    CREATE USER nextcloud WITH PASSWORD 'changeme';
    ALTER DATABASE nextcloud OWNER TO nextcloud;
    GRANT ALL ON DATABASE nextcloud TO nextcloud;
    EOF

Download & extract Nextcloud server:

    sudo mkdir /var/www
    sudo chown -R www-data:www-data /var/www
    sudo chmod -R 755 /var/www
    cd /var/www
    sudo wget https://download.nextcloud.com/server/releases/latest.zip
    sudo unzip latest.zip
    sudo chown -R www-data:www-data /var/www/nextcloud
    sudo rm -r latest.zip
    sudo mkdir /mnt/ncdata/skeleton
    sudo chown -R www-data:www-data /mnt/ncdata/skeleton


### Begin the Nextcloud installation
Open your web browser and go to: http://[LXC_EXTERNAL_IP]

<img width="717" height="961" alt="Captura desde 2025-07-31 13-59-56" src="https://github.com/user-attachments/assets/80fa2660-449c-4cc5-8151-e6204ec1c0d4" />

Set a name and password for the nextcloud admin account, for the database use the same name, user and password created in this step.

For the Nextcloud data dir, set the configured mountpoint of your ZFS dataset, in this case `/mnt/ncdata`

In database host, use the unix socket path: `/var/run/postgresql`
for the port just leave it blank.

And click Install.

<br/><br/><br/>
<img width="708" height="961" alt="Captura desde 2025-07-31 14-01-05" src="https://github.com/user-attachments/assets/5a8dbbbe-0741-4d94-ae87-70eec35ba6fb" />

Select apps as needed, or click Skip to not install anything.

<br/><br/><br/>
<img width="1879" height="961" alt="Captura desde 2025-07-31 14-01-38" src="https://github.com/user-attachments/assets/0c25ad0a-bd57-4dfa-9c9a-0d4573b79551" />

And there we go!

<br/><br/>
### Nextcloud post-installation adjustements:
Go to the administration settings to see what we need to adjust/fix.
<img width="1535" height="683" alt="Captura desde 2025-07-31 14-05-27 (Editado)" src="https://github.com/user-attachments/assets/79a2c356-1890-453f-8110-2ac2ec544913" />

<br/><br/><br/>
Fix database index:

    sudo -u www-data php -f /var/www/nextcloud/occ db:add-missing-indices
    sudo -u www-data php -f /var/www/nextcloud/occ maintenance:repair --include-expensive

<br/><br/>
Configuring Background Jobs:
Go to basic settings and select Cron.

<img width="1085" height="398" alt="Captura desde 2025-07-31 14-07-28" src="https://github.com/user-attachments/assets/b8860656-b710-4665-92cc-b777be12fab4" />

Then open your LXC terminal and add the cronjob:

     sudo crontab -u www-data -e

    # Nextcloud Background Jobs
    #*/5  *  *  *  * php -f /var/www/nextcloud/cron.php
    
    Optional background cronjobs provided by this repository
    # Notify Maintenance Mode
    0 0 * * * bash /opt/nextconf/maintenance-notify.sh
    # Enable Maintenance mode
    0 1 * * * bash /opt/nextconf/set-maintenance.sh on
    # Disable Maintenance mode
    0 6 * * * bash /opt/nextconf/set-maintenance.sh off

<br/><br/>
For the email configuration, you can use your own gmail account following this [video](https://www.youtube.com/watch?v=7NqL9ccYOlk&t).

Or if you have a web domain you can use an email provider, I recommend you the free tier of Mailjet. Please check this [guide](https://franzramadhan.dev/blog/01-free-own-domain-email-using-cloudflare-mailjet/) for more details.

Once you got your mailjet credentials you can add it to nextcloud like this:
<img width="1113" height="477" alt="Captura desde 2025-07-29 22-28-31" src="https://github.com/user-attachments/assets/e1f62ac1-7f76-414b-b983-a5cc8c0fa039" />

<br/><br/><br/>
**Adding redis, memcached and apcu support.**

Edit `/var/www/nextcloud/config/config.php` with the following:

    'memcache.local' => '\\OC\\Memcache\\APCu',
    'memcache.distributed' => '\\OC\\Memcache\\Redis',
    'memcache.locking' => '\\OC\\Memcache\\Redis',
    'redis' => 
    array (
      'host' => '/run/redis/redis-server.sock',
      'port' => 0,
      'password' => 'yourredispassword',
      'dbindex' => 1,
      'timeout' => 0.5,
    ),

  
Another adjustements based in the Nextcloud-AIO configuration, pick the ones you need:

    'skeletondirectory' => '/mnt/ncdata/skeleton', // To create new user accounts without the initial files.
    'log_type' => 'file',
    'logfile' => '/var/www/nextcloud/data/nextcloud.log',
    'log_rotate_size' => 10485760,
    'log.condition' => 
    array (
      'apps' => 
        array (
          0 => 'admin_audit',
        ),
    ),
    'trusted_proxies' => 
    array (
      0 => '127.0.0.1',
      1 => '::1',
    ),
    'preview_max_x' => 2048,
    'preview_max_y' => 2048,
    'jpeg_quality' => 60,
    'preview_max_memory' => 512,
    'enabledPreviewProviders' => 
    array (
      0 => 'OC\\Preview\\Image',
      1 => 'OC\\Preview\\MarkDown',
      2 => 'OC\\Preview\\MP3',
      3 => 'OC\\Preview\\TXT',
      4 => 'OC\\Preview\\OpenDocument',
      5 => 'OC\\Preview\\Krita',
      6 => 'OC\\Preview\\Movie',
      7 => 'OC\\Preview\\PDF',
      8 => 'OC\\Preview\\HEIC',
      9 => 'OC\\Preview\\TIFF',
    ),
    'enable_previews' => true,
    'share_folder' => '/Shared',
    'maintenance_window_start' => 10, // It run maintenance tasks at 06:00AM UTC and up.
    'allow_local_remote_servers' => true,
    'davstorage.request_timeout' => 86400,
    'htaccess.RewriteBase' => '/', // For pretty urls
    'dbpersistent' => false,
    'default_phone_region' => 'US', // Set this based on your country code.
    'trashbin_retention_obligation' => 'auto, 30',
    'versions_retention_obligation' => 'auto, 30',
    'activity_expire_days' => 30,
    'simpleSignUpLink.shown' => false,
    'files.chunked_upload.max_size' => 104857600,
    'forbidden_filename_characters' => 
    array (
      0 => '<',
      1 => '>',
      2 => ':',
      3 => '"',
      4 => '|',
      5 => '?',
      6 => '*',
      7 => '\\',
      8 => '/',
      9 => '~',
      10 => '$',
    ),
    'forbidden_filename_extensions' => 
    array (
      0 => ' ',
      1 => '.',
      2 => '.filepart',
      3 => '.part',
    ),
    'forbidden_filename_basenames' => 
    array (
      0 => 'con',
      1 => 'prn',
      2 => 'aux',
      3 => 'nul',
      4 => 'com0',
      5 => 'com1',
      6 => 'com2',
      7 => 'com3',
      8 => 'com4',
      9 => 'com5',
      10 => 'com6',
      11 => 'com7',
      12 => 'com8',
      13 => 'com9',
      14 => 'com¹',
      15 => 'com²',
      16 => 'com³',
      17 => 'lpt0',
      18 => 'lpt1',
      19 => 'lpt2',
      20 => 'lpt3',
      21 => 'lpt4',
      22 => 'lpt5',
      23 => 'lpt6',
      24 => 'lpt7',
      25 => 'lpt8',
      26 => 'lpt9',
      27 => 'lpt¹',
      28 => 'lpt²',
      29 => 'lpt³',
    ),

Apply the configuration with:

    sudo systemctl restart nginx php8.4-fpm redis-server

**CONGRATULATIONS!**, now your Nextcloud server is fully operational. 

If you want to configure the proxy for selfhosting, please check this [guide](https://github.com/JMarcosHP/Nextcloud-Guide/blob/main/extras/proxy-config.md#nextcloud-configuration). 

<br/><br/>
### Adding Push Notifications support
First enable notifications, open a browser and login with the admin account.
Go to the Administration settings => Notifications
And set this configuration:

<img width="548" height="292" alt="Captura desde 2025-07-29 23-26-49" src="https://github.com/user-attachments/assets/b9626278-cd48-404e-8628-673dac4df6cb" />


Install the notify_push app with:

    sudo -u www-data php -f /var/www/nextcloud/occ app:install notify_push

Then copy the systemd service unit in `/etc/systemd/system/notify_push.service` provided by this repository:

    sudo cp -r /opt/nextconf/notify_push.service /etc/systemd/system/

*NOTE: If you used the Nginx configuration of this repository you don't need to edit it, because already has the required proxy_pass location for notifications. Only change the systemd unit if you are using https.*

Reload Systemd and start the service:

    sudo systemctl daemon-reload
    sudo systemctl enable --now notify_push.service

Configure the app with the correct URL:

    sudo -u www-data php -f /var/www/nextcloud/occ notify_push:setup http://[EXTERNAL LXC IP]/push # Example http://192.168.1.9/push

If you already configured your server behind a ssl proxy, simply execute:

    sudo -u www-data php -f /var/www/nextcloud/occ notify_push:setup https://yourdomain.example/push

Changes to the systemd unit are not needed in this case. However if you are on full https without proxy or a local https instance then change the systemd unit first.

Finally restart Nginx and PHP:

    sudo systemctl restart nginx php8.4-fpm

*NOTE: Some browsers will block notifications and sound by default in http websites.*

This repository includes a script to test notifications:

    cd /opt/nextconf
    sudo chmod +x maintenance-notify.sh
    sudo -u www-data ./maintenance-notify.sh

You will see a notification of the browser.

<br/><br/>
### Setup automatic preview generation
Install the previews app:

    sudo -u www-data php -f /var/www/nextcloud/occ app:install previewgenerator

Add the cronjob:

    sudo chmod +x /opt/nextconf/previews.sh
    sudo crontab -u www-data -e
    
    # Nextcloud Previews
    */5 * * * * /opt/nextconf/previews.sh

<br/><br/>
### Memories app setup

Install the memories app:

    sudo -u www-data php -f /var/www/nextcloud/occ app:install memories

Download the planet database:

    sudo -u www-data php -f /var/www/nextcloud/occ memories:places-setup

Now go to the configuration page and check if everything is OK.

Recommended configuration for memories:

<img width="1375" height="864" alt="Captura desde 2025-07-31 18-59-29" src="https://github.com/user-attachments/assets/4911d88c-ecfc-44ea-8169-f6ac0bceb4fb" />

<img width="1375" height="888" alt="Captura desde 2025-07-31 18-59-59" src="https://github.com/user-attachments/assets/af1ee67d-d9e2-4d9c-b6ad-79ddfac840f6" />

<img width="1372" height="897" alt="Captura desde 2025-07-31 19-00-06" src="https://github.com/user-attachments/assets/a80d7eff-af3a-45c9-8d10-a49da427e814" />

<img width="1372" height="888" alt="Captura desde 2025-07-31 19-00-23" src="https://github.com/user-attachments/assets/efec8d27-4b91-4246-951d-3a85449fe29f" />

<img width="1362" height="890" alt="Captura desde 2025-07-31 19-00-39" src="https://github.com/user-attachments/assets/882658ff-fe44-4982-9e83-b18640bb3720" />

(Only with GPU Passthrough, enable VA-API, for nvidia you need to install the corresponding driver with: sudo apt install nvidia-driver)

## Extras
Some usefull guides to complement your fresh Nextcloud instance.

- [Selfhost/Proxy/HTTPS/SSL Support with Nginx Proxy Manager LXC](https://github.com/JMarcosHP/Nextcloud-Guide/blob/main/extras/proxy-config.md)
- [How to install OnlyOffice Document Server 9](https://github.com/JMarcosHP/Nextcloud-Guide/blob/main/extras/onlyoffice-setup.md)
- [How to install Adminer for database administration GUI](https://github.com/JMarcosHP/Nextcloud-Guide/blob/main/extras/adminer-setup.md)
- [How to migrate to a newer PHP version](https://github.com/JMarcosHP/Nextcloud-Guide/blob/main/extras/php-upgrades.md)
- [How to migrate to a newer PostgreSQL version](https://github.com/JMarcosHP/Nextcloud-Guide/blob/main/extras/postgresql-upgrades.md)
- [How to upgrade Debian to a newer release](https://github.com/JMarcosHP/Nextcloud-Guide/blob/main/extras/debian-release-upgrades.md)
- How to upgrade Nextcloud (work in progress)
- How to make a LXC Snapshot Backup in Proxmox (work in progress)
