FROM blueimp/php:5.6

COPY php.ini /etc/php5/fpm/conf.d/99-custom.ini
COPY ssmtp.conf /etc/ssmtp/
COPY envconfig.conf /usr/local/etc/
COPY entrypoint.d /usr/local/etc/entrypoint.d
