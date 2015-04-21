FROM busybox

# Create the redis data directory:
RUN mkdir -p /data/redis

# Assign the directory to the redis user+group:
RUN chown -R 400:400 /data/redis

VOLUME ["/data/redis"]
WORKDIR /data/redis

CMD ["echo", "redis data"]

LABEL test.dev.service=redisdata
