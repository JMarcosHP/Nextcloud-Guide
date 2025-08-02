# HOW TO MIGRATE TO A NEWER POSTGRESQL VERSION

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
	+ [STEP 7](#step-7)
	+ [STEP 8 (Optional)](#step-8-optional)

## Why upgrade PostgreSQL?

- Your current PostgreSQL version will be unsupported on the next release of Nextcloud.
- You need a new feature or Nextcloud complains about a required feature.
- Your current PostgreSQL version is reaching EOL.

## When to migrate to a newer version?

Unlike PHP, you can maintain the same version of PostgreSQL for much longer without requiring an upgrade to a major release (At least 5 years). And the migration is even more flexible and easier to do, that's why this guide uses PostgreSQL over MySQL.

If you don't want to spent much time upgrading, only upgrade when your current version is reaching EOL, Nextcloud requires a new feature, or that version will be unsupported by Nextcloud soon.

## Which version to migrate to?

For production instances, I would generally recommend sticking with the versions that Nextcloud officially supports, first check what's the latest PostgreSQL version officialy supported in the latest Nextcloud release at that time, and then make the jumb to that version before upgrading your Nextcloud instance. You can check [here](https://docs.nextcloud.com/server/latest/admin_manual/installation/system_requirements.html#:~:text=PostgreSQL).

## GUIDE

This guide assumes you are using the official [PostgreSQL repository](https://www.postgresql.org/download/linux/debian/#:~:text=apt%20install%20postgresql-,PostgreSQL%20Apt%20Repository,-If%20the%20version) in your server, otherwise, this might not work for you.

### STEP 1:
Make a snapshot of your LXC Container, if anything goes wrong, just restore the snapshot and start the migration again.

### STEP 2:
Enable maintenance mode in Nextcloud.

    sudo -u www-data php -f /opt/nextconf/maintenance-mode.sh --on

### STEP 3:
Install the new PostgreSQL version and client:

    sudo apt install -y postgresql-xx postgresql-client-xx # Replace xx with the desired version.

### STEP 4:
Drop the default cluster created upon installation.

    sudo pg_dropcluster xx main --stop # Replace xx with the latest PostgreSQL version installed.

### STEP 5:
Upgrade your cluster. Where `xx` is the latest version you want to upgrade, and `xy` is the current version you are running.

    sudo pg_upgradecluster -v xx xy main # Ex: -v 18 17

By default, the utility migrate the configuration files for you, but if you have custom `conf.d` files, you need to manually copy these to the new `/etc/postgresql/xx/main/conf.d` cluster. And restart the service: `sudo systemctl restart postgresql@xx-main.service`

### STEP 6:
Review cluster status:

    sudo pg_lsclusters

You should see that the old version is down and the latest is running.

### STEP 7:
Disable the maintenance mode in Nextcloud and check if the new PostgreSQL version installed is detected and working as expected. If not, check the Nextcloud logs to see if it has issue trying to connect to the database: `/var/www/nextcloud/data/nextcloud.log`

    sudo -u www-data php -f /opt/nextconf/maintenance-mode.sh --off

### STEP 8 (Optional):
Clean old cluster and packages.

    sudo pg_dropcluster xy main
    sudo apt remove --purge postgresql-xy postgresql-client-xy
