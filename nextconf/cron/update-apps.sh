#!/bin/bash
# Script to update all Nextcloud apps automatically. Needs to run as www-data user.
# sudo -E -u www-data
# Or set an automated cronjob:
# sudo crontab -u www-data -e
#
# Please don't execute this script during maintenance mode operations, as it is discouraged by the Nextcloud manual.

php -f /var/www/nextcloud/occ app:update --all

