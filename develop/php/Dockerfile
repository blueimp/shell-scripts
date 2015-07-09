FROM blueimp/php:5.6

COPY php.ini /etc/php5/fpm/conf.d/99-custom.ini
COPY crontab /etc/crontab
COPY ssmtp.conf /etc/ssmtp/ssmtp.conf

COPY envconfig.sh /usr/local/bin/envconfig
COPY envconfig.conf /usr/local/etc/envconfig.conf

COPY entrypoint.sh /usr/local/bin/entrypoint

ENTRYPOINT ["envconfig", "entrypoint"]

CMD ["php5-fpm"]
