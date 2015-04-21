FROM blueimp/php

COPY php.ini /etc/php5/fpm/conf.d/99-custom.ini
COPY ssmtp.conf /etc/ssmtp/ssmtp.conf
COPY crontab /etc/crontab

COPY ssh /var/www/.ssh
RUN chown -R www-data:www-data /var/www
RUN chmod 600 /var/www/.ssh/*

LABEL test.dev.service=php
