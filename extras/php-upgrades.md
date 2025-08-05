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

    sudo -u www-data php -f /opt/nextconf/cron/maintenance-mode.sh --on

### STEP 3:
Install the new PHP packages and extensions.
Change `X.Y` to the desired PHP version, please don't use the metapackages:

    sudo apt install -y phpX.Y-{fpm,pgsql,gd,curl,mbstring,xml,zip,intl,bcmath,gmp,imagick,redis,apcu,smbclient,ldap,imap}

### STEP 4:
Set the newer PHP as default.
Select the corresponding `phpX.Y` version in `update-alternatives`
This lets you switch the php socket symlink to the new version:

    sudo update-alternatives --config php-fpm.sock

And this to set the default php binary:

    sudo update-alternatives --config php

Stop and disable the old phpX.X-fpm service:

    sudo systemctl disable --now phpX.X-fpm.service # Adjust to the old PHP version

If you want to keep many PHP versions, you will need to adjust the socket name in the dedicated `zz-nextcloudpool.conf` of every PHP version to not conflict the listening of every version. Nginx configuration is needed only if you have set a manual `phpX.Y-fpm.sock` or `phpX.Y-fpm-nextcloud.sock` for `php-handler`.

### STEP 5:
Migrate configuration.

This repository provides configuration templates for PHP-FPM and pools, if you already configured these templates simply copy them to your new PHP version folder:

    sudo cp -r /opt/nextconf/php/nextcloud.ini /etc/php/X.Y/mods-available 
    sudo cp -r /opt/nextconf/php/zz-nextcloudpool.conf /etc/php/X.Y/fpm/pool.d

Then load the configuration, restart the new PHP service and see if it's running without issues:

    sudo phpenmod -v X.Y -s fpm nextcloud
    sudo systemctl restart phpX.Y-fpm.service
    sudo systemctl status phpX.Y-fpm.service

However, if you don't have these templates, you can download the nextcloud.ini template [here](https://github.com/JMarcosHP/Nextcloud-Guide/blob/main/nextconf/php/nextcloud.ini), and the zz-nextcloudpool.conf [here](https://github.com/JMarcosHP/Nextcloud-Guide/blob/main/nextconf/php/zz-nextcloudpool.conf) for the pool.
Adjust them with your current values and apply the configuration.

### STEP 6:
Disable the maintenance mode in Nextcloud and check if the new PHP version installed is detected and working as expected, if not, double check your PHP settings and the default socket and binary used. 

    sudo -u www-data php -f /opt/nextconf/cron/maintenance-mode.sh --off

### STEP 7 (Optional):

Once you tested everything works, uninstall the older PHP packages.

    sudo apt remove --purge phpX.Y*
    sudo apt autoremove --purge
