#!/bin/sh

sed -i "s/{{SSMTP_AUTH_PASS}}/${SSMTP_AUTH_PASS}/" /etc/ssmtp/ssmtp.conf

echo "$SSL_CRT" >> /etc/nginx/ssl/dev.test.crt
echo "$SSL_KEY" >> /etc/nginx/ssl/dev.test.key

echo "$SSH_PRIVATE_KEY" >> /var/www/.ssh/id_rsa
echo "$SSH_PUBLIC_KEY" >> /var/www/.ssh/id_rsa.pub
echo "$SSH_KNOWN_HOSTS" >> /var/www/.ssh/known_hosts

echo "$SSH_PRIVATE_KEY" >> /root/.ssh/id_rsa
echo "$SSH_PUBLIC_KEY" >> /root/.ssh/id_rsa.pub
echo "$SSH_KNOWN_HOSTS" >> /root/.ssh/known_hosts
