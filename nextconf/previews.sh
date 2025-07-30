#!/bin/bash
# Script to generate previews in Nextcloud server, requires "previewgenerator" app installed in your server, and needs to run as www-data user.
# sudo -u www-data
# Or set an automated cronjob:
# sudo crontab -u www-data -e

php -f /var/www/nextcloud/occ preview:pre-generate

# Uncomment the following line for Nextcloud-AIO support. Needs to run as root user or a user added in the docker group.
# docker exec --user www-data --tty nextcloud-aio-nextcloud php occ preview:pre-generate
