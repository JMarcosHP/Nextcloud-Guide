# How to upgrade Nextcloud
**Table of Contents:**
 + [Why upgrade Nextcloud?](#why-upgrade-nextcloud)
 + [When to upgrade to a newer version?](#when-to-upgrade-to-a-newer-version)
 + [Approaching Upgrades](#approaching-upgrades)
 + [Guide](#guide)
	+ [STEP 1](#step-1)
	+ [STEP 2 (Optional)](#step-2-optional)
	+ [STEP 3](#step-3)
	+ [STEP 4](#step-4)
	+ [STEP 5](#step-5)
 	+ [STEP 6](#step-6) 

## Why upgrade Nextcloud?

- Your current instance is reaching EOL.
- You need a new Nextcloud feature.
- You need a patch or a performance improvement offered by the next release.

## When to upgrade to a newer version?

You have two paths to upgrade to, point releases or major version releases.
Point releases only provide bug fixes for your current version installed, major releases provide newer features, apps, and performance improvements.

Every major version is supported for 1 year. And a new version is released approximately every 4 months.
You have a new point release every month.

That's too many upgrades, isn't it?

Well for this case the recommendation is to stick with point releases as much possible (upgrade to the latest point release every 2 or 3 months) until you reach EOL for your release, then proceed to upgrade to a new major version. With this approach you reduce the work and time spent maintaining your Nextcloud server and ensures compatibility for all your Nextcloud apps installed.

But if you feel brave and want the latest and greatest, please have some self-respect and wait at least to the third point release of the new major version.

## Approaching Upgrades

Nextcloud must be upgraded step by step:

-   Before you can upgrade to the next major release, you need to upgrade to the latest point release of your current major version.
    
-   Then run the upgrade again to upgrade to the next major release’s latest point release.
    
-   **You cannot skip major releases.**  Please re-run the upgrade until you have reached the highest available (or applicable) release.
    
-   Example: 18.0.5 -> 18.0.11 -> 19.0.5 -> 20.0.2
    

**Wait for background migrations to finish after major upgrades**. After upgrading to a new major version, some migrations are scheduled to run as a background job. If you plan to upgrade directly to another major version (e.g. 24 -> 25 -> 26) you need to make sure these migrations were executed before starting the next upgrade. To do so you should run the  `cron.php`  file 2-3 times, for example:

    sudo -E -u www-data php -f /var/www/nextcloud/cron.php

## GUIDE

For this guide we will use the CLI method to upgrade Nextcloud. For a GUI based guide please refer to the [Nextcloud manual](https://docs.nextcloud.com/server/latest/admin_manual/maintenance/update.html#using-the-web-based-updater).

### STEP 1:

Make a snapshot of your LXC Container, if anything goes wrong, just restore the snapshot and start the upgrade again.

### STEP 2 (Optional):

**PREREQUISITES**

If you are upgrading to a new major release, please check the [Nextcloud Admin Manual](https://docs.nextcloud.com/server/latest/admin_manual/release_notes/index.html) for critical/breaking changes in the stack like web server, PHP, database and Nextcloud configurations. Select your desired release and make the necessary adjustements to your server before the upgrade.

### STEP 3:

Set your Nextcloud instance to maintenance mode:

    sudo -u www-data /opt/nextconf/cron/maintenance-mode.sh --on

### STEP 4:

Perform the upgrade:

    sudo -E -u www-data php  /var/www/nextcloud/updater/updater.phar

![../_images/updater-cli-3-running-step.png](https://docs.nextcloud.com/server/latest/admin_manual/_images/updater-cli-3-running-step.png)
Verify the information that is shown and enter “Y” to start the update.

<br/><br/><br/>
![../_images/updater-cli-4-failed-step.png](https://docs.nextcloud.com/server/latest/admin_manual/_images/updater-cli-4-failed-step.png)
In case an error happens or the check failed the updater stops processing and gives feedback. You can now try to solve the problem and re-run the updater command. This will continue the update and re-run the failed step. It will not re-run the previous succeeded steps.

<br/><br/><br/>
![../_images/updater-cli-6-run-command.png](https://docs.nextcloud.com/server/latest/admin_manual/_images/updater-cli-6-run-command.png)
Once all steps are executed the updater will ask you a final question: “Should the “occ upgrade” command be executed?”. This allows you to directly execute the command line based upgrade procedure (`occ  upgrade`). Select "yes" to finish the upgrade.

<br/><br/><br/>
![../_images/updater-cli-7-maintenance.png](https://docs.nextcloud.com/server/latest/admin_manual/_images/updater-cli-7-maintenance.png)
Once the  `occ  upgrade`  is done you get asked if the maintenance mode should be kept active, type "N".

### STEP 5:

Fix the database layout:

    sudo -E -u www-data php -f /var/www/nextcloud/occ db:add-missing-columns
    sudo -E -u www-data php -f /var/www/nextcloud/occ db:add-missing-indices
    sudo -E -u www-data php -f /var/www/nextcloud/occ maintenance:repair --include-expensive
    sudo -E -u www-data php -f /var/www/nextcloud/occ db:add-missing-primary-keys

### STEP 6:
Now go to the administration page in Nextcloud and see any warning or configuration that needs your attention.
