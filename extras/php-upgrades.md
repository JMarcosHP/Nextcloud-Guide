# HOW TO MIGRATE TO A NEWER PHP VERSION

**Table of Contents:**
 + [Why upgrade PHP?](#why-upgrade-php)
 + [When to migrate to a newer version?](#when-to-migrate-to-a-newer-version)
 + [Which version to migrate to?](#which-version-to-migrate-to)
 + [Guide](#guide)
	+ [STEP 1](#step-1)
	+ [STEP 2](#step-2)
	+ [STEP 3](#step-3)
	+ [STEP 4](#step-4)
	+ [STEP 5](#step-5)
	+ [STEP 6](#step-6)
	+ [STEP 7](#step-7-optional)

## Why upgrade PHP?

- You upgraded your Nextcloud Server and now your current PHP installed hits the deprecation notice.
- You need a new feature or Nextcloud complains about a required feature.
- Your current PHP has a critical vulnerability and newer versions have the corresponding patch.

## When to migrate to a newer version?

It's recommended to migrate only when you hit the deprecation notice in Nextcloud, if you upgrade your php too often it can lead to several regressions and bugs, or Nextcloud will not support (at that time) a bleeding edge PHP version.

## Which version to migrate to?

If your PHP version gets deprecated, it's recommended to do the jumb to the latest PHP runtime supported in Nextcloud at that time (assuming you are running the latest Nextcloud release) before upgrading your Nextcloud instance. You can check it in the Nextcloud [requirements.](https://docs.nextcloud.com/server/latest/admin_manual/installation/system_requirements.html#:~:text=with%20php%2Dfpm-,PHP%20Runtime)

By doing this, you reduce the work and time spent maintaining your Nextcloud server.

## GUIDE

This guide assumes you are using [Sury's PHP repository](https://deb.sury.org/) in your server, otherwise, this might not work for you.

### STEP 1:
Make a snapshot of your LXC Container, if anything goes wrong, just restore the snapshot and start the migration again.

### STEP 2:
Enable maintenance mode in Nextcloud.

    sudo -u www-data php -f /opt/nextconf/maintenance-mode.sh --on

### STEP 3:
Install the new PHP packages and extensions.
Change `X.Y` to the desired PHP version, please don't use the metapackages:

    sudo apt install -y phpX.Y-{fpm,pgsql,gd,curl,mbstring,xml,zip,intl,bcmath,gmp,imagick,redis,apcu,smbclient,ldap,imap}

### STEP 4:
Migrate configuration.
Compare the settings rather than blindly copying old `php.ini/www.conf` files.
It is recommended to only set the configuration you modified for the nextcloud/redis setup in `/etc/php/X.Y/fpm/php.ini`, these are the configuration parameters provided by this guide:

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

And for `/etc/php/X.Y/fpm/pool.d/www.conf` just set the calculated pm values from the older `www.conf` file:

    pm = dynamic # Or static
    pm.max_children = 
    pm.start_servers = 
    pm.min_spare_servers = 
    pm.max_spare_servers =

Uncomment the following line:

    ;env[PATH] = /usr/local/bin:/usr/bin:/bin

Then restart the new PHP service and see if it's running without issues:

    sudo systemctl restart phpX.Y-fpm.service
    sudo systemctl status phpX.Y-fpm.service

### STEP 5:
Set the newer PHP as default.
Select the corresponding `phpX.Y` version in `update-alternatives`
This lets you switch the php socket symlink to the new version:

    sudo update-alternatives --config php-fpm.sock

And this to set the default php binary:

    sudo update-alternatives --config php

You can keep many PHP versions as you need. Nginx configuration is needed only if you have set a manual `phpX.Y-fpm.sock` for `php-handler`.

### STEP 6:
Disable the maintenance mode in Nextcloud and check if the new PHP version installed is detected and working as expected, if not, double check your PHP settings and the default socket and binary used. 

    sudo -u www-data php -f /opt/nextconf/maintenance-mode.sh --off

### STEP 7 (Optional):

Once you tested everything works, uninstall the older PHP packages.

    sudo apt remove --purge phpX.Y*
    sudo apt autoremove --purge
