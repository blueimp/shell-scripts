#!/bin/sh
set -e

# Adjust ownership and permissions for the www-data ssh configuration:
chown -R www-data:www-data /var/www
chmod 600 /var/www/.ssh/*

# Start the given command:
exec "$@"
