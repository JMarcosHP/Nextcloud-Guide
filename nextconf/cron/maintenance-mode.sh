#!/bin/bash
# Script to set Nextcloud in maintenance mode. Needs to run as www-data user.
# sudo -E -u www-data
# Or set an automated cronjob:
# sudo crontab -u www-data -e

php -f /var/www/nextcloud/occ maintenance:mode --$1

# Uncomment the following line for Nextcloud-AIO support. Needs to run as root user or a user added in the docker group.
# docker exec -u www-data nextcloud-aio-nextcloud php occ maintenance:mode --$1

