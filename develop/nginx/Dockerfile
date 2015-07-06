FROM blueimp/nginx:1.8

COPY conf.d /etc/nginx/conf.d

COPY envconfig.sh /usr/local/bin/envconfig
COPY envconfig.conf /usr/local/etc/envconfig.conf

ENTRYPOINT ["envconfig", "nginx", "-g", "daemon off;"]
