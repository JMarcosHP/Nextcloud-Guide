# HOW TO UPGRADE DEBIAN TO A NEWER RELEASE

**Table of Contents:**
 + [Why upgrade Debian?](#why-upgrade-debian)
 + [When to upgrade to a newer release?](#when-to-upgrade-to-a-newer-release)
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
	+ [STEP 10](#step-10)
	+ [STEP 11](#step-11)
	+ [STEP 12](#step-12)
	+ [STEP 13 (Optional)](#step-13-optional)


## Why upgrade Debian?

 - Your current release is reaching EOL.
- The stack repositories (nginx, php, redis, postgresql) stopped supporting your current release.
- You need newer package versions.

## When to upgrade to a newer release?

If it works, why change it? Well, Debian stable releases have a support lifecycle consisting of three years of full support followed by two years of Long Term Support, 5 years of support in total. That's a lot of time for planning migrations, for production servers it's always recommended to upgrade a few months before reaching the EOL, because many repositories will shutdown and leave you without updates.

However if you want the latest and greatest, wait at least 6 months after the next major release to let the developers iron the remaining bugs and the external repositories start supporting that release.

## GUIDE
This guide assumes you are using Sury's NGINX/PHP, PostgreSQL and Redis repositories in your server, otherwise, this might not work for you.

### STEP 1:
Make a snapshot of your LXC Container, if anything goes wrong, just restore the snapshot and start the upgrade again.

### STEP 2:
Check repository availability for the next major release:

 - [Sury's PHP](https://packages.sury.org/php/dists/)
 - [Sury's Nginx](https://packages.sury.org/nginx/dists/)
 - [PostgreSQL](https://www.postgresql.org/download/linux/debian/#:~:text=The%20PostgreSQL%20Apt%20repository%20supports%20the%20current%20versions%20of%20Debian:)
 - [Redis](https://github.com/redis/redis-debian?tab=readme-ov-file#supported-operating-systems)

If any of the above repositories are not yet available for the next major release, please postpone upgrading until all of them are available, to not risk breaking your system.

*NOTE:*
*The OnlyOffice [repo](https://helpcenter.onlyoffice.com/en/docs/installation/docs-community-install-ubuntu.aspx#:~:text=While%20the%20APT%20package%20is%20built%20against%20Debian%20Squeeze,%20it%20is%20compatible%20with%20a%20number%20of%20Debian%20derivatives%20%28including%20Ubuntu%29%20which%20means%20you%20can%20use%20the%20same%20repository%20across%20all%20these%20distributions.) is not covered here because it has only one codename to distribute the software for all Debian-based distros.*

### STEP 3:
Enable maintenance mode in Nextcloud.

    sudo -u www-data php -f /opt/nextconf/cron/maintenance-mode.sh --on

### STEP 4:
Apply pending updates on your current system.

    sudo apt update && sudo apt upgrade -y

### STEP 5:
Edit your repo list and point it to the next codename.
For example, if you want to upgrade from bookworm to trixie:

    /etc/apt/sources.list
    deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
    deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
    deb http://security.debian.org trixie-security main contrib non-free non-free-firmware

    /etc/apt/sources.list.d/nginx.list
    deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/nginx/ trixie main

    /etc/apt/sources.list.d/php.list
    deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ trixie main

    /etc/apt/sources.list.d/redis.list
    deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb trixie main
    
    /etc/apt/sources.list.d/pgdg.sources
    Types: deb
    URIs: https://apt.postgresql.org/pub/repos/apt
    Suites: trixie-pgdg
    Components: main
    Signed-By: /usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg

### STEP 6:
Update repository package list.

    sudo apt update

### STEP 7:
Perform the upgrade to the next major release.

    sudo apt upgrade --without-new-pkgs
    sudo apt full-upgrade

### STEP 8:
Post-upgrade verification.
Confirm successful upgrade completion:

    cat /etc/os-release

### STEP 9:
Confirm that your stack services are running without issues.

    sudo systemctl status nginx phpX.Y-fpm postgresql@xx-main redis-server

If not, you have to manually fix your services according to the problem you see in the status.

### STEP 10:
Cleanup.

    sudo apt autoremove --purge
    sudo apt autoclean

### STEP 11:
Restart the container.

    sudo reboot

### STEP 12:
Disable maintenance mode in Nextcloud and check if everything is correct, if not, check the Nextcloud logs in `/var/www/nextcloud/data/nextcloud.log`.

    sudo -u www-data php -f /opt/nextconf/cron/maintenance-mode.sh --off

### STEP 13 (Optional):
Modernize your sources to the new format.

    sudo apt modernize-sources

