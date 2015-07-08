FROM busybox

# Create the redis data directory and assign it to the redis user+group:
RUN mkdir -p /data/redis \
  && chown -R 400:400 /data/redis

VOLUME /data/redis
WORKDIR /data/redis

CMD ["echo", "redis data"]
