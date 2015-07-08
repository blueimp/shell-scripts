FROM busybox

# Create the data directory and assign it to the elasticsearch user+group:
RUN mkdir -p /usr/share/elasticsearch/data \
  && chown -R 500:500 /usr/share/elasticsearch/data

VOLUME /usr/share/elasticsearch/data
WORKDIR /usr/share/elasticsearch/data

CMD ["echo", "elasticsearch data"]
