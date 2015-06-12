FROM busybox

# Create the mongodb data directory:
RUN mkdir -p /data/db

# Assign the directory to the mongodb user+group:
RUN chown -R 300:300 /data/db

VOLUME /data/db
WORKDIR /data/db

CMD ["echo", "mongodb data"]

LABEL test.dev.service=mongodbdata
