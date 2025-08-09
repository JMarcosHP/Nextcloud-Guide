#!/bin/bash
# Script to send a daily maintenance notification in Nextcloud. Needs to run as www-data user.
# sudo -E -u www-data
# Or set an automated cronjob:
# sudo crontab -u www-data -e

php -f /var/www/nextcloud/occ user:list | sed 's/.*- \(.*\):.*/\1/' | \
xargs -i php -f /var/www/nextcloud/occ notification:generate {} \
"Scheduled Maintenance Reminder" --long-message="Nextcloud will be in maintenance mode at 01:00 AM. Save your work in advance!"

# Uncomment the following lines for Nextcloud-AIO support. Needs to run as root user or a user added in the docker group.
#docker exec -u www-data nextcloud-aio-nextcloud php occ user:list | sed 's/.*- \(.*\):.*/\1/' | \
#xargs -i docker exec -u www-data nextcloud-aio-nextcloud php occ notification:generate {} \
#"Scheduled Maintenance Reminder" --long-message="Nextcloud will be in maintenance mode daily at 01:00 AM. Save your work in advance!"
