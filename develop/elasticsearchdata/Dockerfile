FROM busybox

# Create the elasticsearch data directory:
RUN mkdir -p /usr/share/elasticsearch/data

# Assign the directory to the elasticsearch user+group:
RUN chown -R 500:500 /usr/share/elasticsearch/data

VOLUME /usr/share/elasticsearch/data
WORKDIR /usr/share/elasticsearch/data

CMD ["echo", "elasticsearch data"]

LABEL test.dev.service=elasticsearchdata
