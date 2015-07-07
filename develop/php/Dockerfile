FROM blueimp/php:5.6

COPY php.ini /etc/php5/fpm/conf.d/99-custom.ini
COPY crontab /etc/crontab
COPY ssmtp.conf /etc/ssmtp/ssmtp.conf

COPY envconfig.sh /usr/local/bin/envconfig
COPY envconfig.conf /usr/local/etc/envconfig.conf

# Create empty SSH configuration files to be filled in via envconfig:
RUN mkdir -p /var/www/.ssh \
  && touch \
    /var/www/.ssh/id_rsa \
    /var/www/.ssh/id_rsa.pub \
    /var/www/.ssh/known_hosts \
  && chmod 600 /var/www/.ssh/* \
  && chown -R www-data:www-data /var/www

ENTRYPOINT ["envconfig", "php5-fpm"]
