FROM blueimp/nginx:1.8

# Install the envconfig script:
ADD https://raw.githubusercontent.com/blueimp/docker/1.0.0/bin/envconfig.sh \
  /usr/local/bin/envconfig
RUN chmod +x /usr/local/bin/envconfig

# Copy configuration files:
COPY conf.d /etc/nginx/conf.d
COPY envconfig.conf /usr/local/etc/envconfig.conf

ENTRYPOINT ["envconfig"]

CMD ["nginx", "-g", "daemon off;"]
