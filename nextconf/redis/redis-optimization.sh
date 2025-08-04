#!/bin/bash
# Script to optimize redis server. Needs to run as root user.
# Or set an automated cronjob:
# sudo crontab -e

redis-cli -s /run/redis/redis-server.sock -a 'yourredispassword' <<EOF
FLUSHALL
quit
EOF
