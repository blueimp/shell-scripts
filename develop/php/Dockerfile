FROM blueimp/php

COPY php.ini /etc/php5/fpm/conf.d/99-custom.ini
COPY crontab /etc/crontab
COPY ssmtp.conf /etc/ssmtp/ssmtp.conf
COPY ssh /var/www/.ssh

COPY envconfig.sh /usr/local/bin/envconfig
COPY envconfig.conf /usr/local/etc/envconfig.conf

# Workaround for boot2docker issue #581, see
# https://github.com/boot2docker/boot2docker/issues/581
# Assume www-data user+group to use 1000 as id:
RUN chown -R 1000:1000 /var/www

ENTRYPOINT ["envconfig", "php5-fpm"]
