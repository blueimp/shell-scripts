FROM blueimp/nginx

COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d /etc/nginx/conf.d

COPY envconfig.sh /usr/local/bin/envconfig
COPY envconfig.conf /usr/local/etc/envconfig.conf

ENTRYPOINT ["envconfig", "nginx", "-g", "daemon off;"]
