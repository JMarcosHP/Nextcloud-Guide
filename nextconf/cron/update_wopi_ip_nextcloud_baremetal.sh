#!/bin/bash
# Script to automatically update Nextcloud's collabora code WOPI IP of your public domain. Requires the "richdocuments" app installed on your server, and needs to run as www-data user.
# sudo -E -u www-data
# Or set an automated cronjob:
# sudo crontab -u www-data -e

# Get the current external IP from ipify for IPv4 and IPv6
ext_ip4=$(curl -s https://api.ipify.org)
ext_ip6=$(curl -s https://api64.ipify.org)

# Log the external IP for debugging
echo "External IPv4 IP: $ext_ip4"
echo "External IPv6 IP: $ext_ip6"

# Get the current WOPI allow list from Nextcloud
current_wopi_list=$(php -f /var/www/nextcloud/occ config:app:get richdocuments wopi_allowlist)
echo "Current WOPI allow list: $current_wopi_list"

# Initialize update flag
update_needed=0
new_ip_list=""

# Check if we have at least one valid IP address
if [ -z "$ext_ip4" ] && [ -z "$ext_ip6" ]; then
    echo "No internet connection. Unable to update IP."
    exit 1
fi

# Process IPv4 if available
if [ -n "$ext_ip4" ]; then
    if [[ "$current_wopi_list" != *"$ext_ip4"* ]]; then
        echo "IPv4 address needs to be updated: $ext_ip4"
        update_needed=1
    else
        echo "IPv4 is up to date: $ext_ip4"
    fi
    
    # Add IPv4 to the new list if it exists
    new_ip_list="$ext_ip4"
fi

# Process IPv6 if available
if [ -n "$ext_ip6" ]; then
    if [[ "$current_wopi_list" != *"$ext_ip6"* ]]; then
        echo "IPv6 address needs to be updated: $ext_ip6"
        update_needed=1
    else
        echo "IPv6 is up to date: $ext_ip6"
    fi
    
    # Add IPv6 to the new list if it exists, with comma if IPv4 exists
    if [ -n "$new_ip_list" ] && [ -n "$ext_ip6" ]; then
        new_ip_list="$new_ip_list,$ext_ip6"
    elif [ -n "$ext_ip6" ]; then
        new_ip_list="$ext_ip6"
    fi
fi

# Update the WOPI allow list if needed
if [ $update_needed -eq 1 ]; then
    echo "Updating WOPI allow list to: $new_ip_list"
    
    # Use bash -c to ensure proper command execution
    php -f /var/www/nextcloud/occ config:app:set richdocuments wopi_allowlist --value=\"$new_ip_list\"
    
    # Check if the IP was successfully set
    if [ $? -eq 0 ]; then
        echo "WOPI allow list updated successfully."
    else
        echo "Failed to update WOPI allow list."
    fi
else
    echo "No updates needed. Current WOPI allow list is up to date."
fi
