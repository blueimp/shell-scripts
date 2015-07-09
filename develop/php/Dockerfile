FROM blueimp/php:5.6

# Install the envconfig script:
ADD https://raw.githubusercontent.com/blueimp/docker/1.0.0/bin/envconfig.sh \
  /usr/local/bin/envconfig
RUN chmod +x /usr/local/bin/envconfig

# Copy configuration files:
COPY php.ini /etc/php5/fpm/conf.d/99-custom.ini
COPY crontab /etc/crontab
COPY ssmtp.conf /etc/ssmtp/ssmtp.conf
COPY envconfig.conf /usr/local/etc/envconfig.conf

# Copy the entrypoint script to adjust ownership and permissions:
COPY entrypoint.sh /usr/local/bin/entrypoint

ENTRYPOINT ["envconfig", "entrypoint"]

CMD ["php5-fpm"]
