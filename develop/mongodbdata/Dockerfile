FROM busybox

# Create the data directory and assign it to the mongodb user+group:
RUN mkdir -p /data/db \
  && chown -R 300:300 /data/db

VOLUME /data/db
WORKDIR /data/db

CMD ["echo", "mongodb data"]
