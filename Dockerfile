ARG BASE_IMAGE=repository.broadleafcommerce.com:5001/broadleaf/zookeeper-base:wolfi-5
FROM ${BASE_IMAGE}

USER root

ENV ZOO_CONF_DIR=/etc/zookeeper \
    ZOO_DATA_DIR=/var/lib/zookeeper/data \
    ZOO_DATA_LOG_DIR=/var/lib/zookeeper/log \
    ZOO_LOG_DIR=/logs \
    ZOOKEEPER_TICK_TIME=2000 \
    ZOOKEEPER_INIT_LIMIT=10 \
    ZOOKEEPER_SYNC_LIMIT=5 \
    ZOOKEEPER_AUTOPURGE_PURGEINTERVAL=24 \
    ZOOKEEPER_AUTOPURGE_SNAPRETAINCOUNT=3 \
    ZOOKEEPER_MAX_CLIENT_CNXNS=60

# Ensure directories exist and have correct permissions for the appuser.
# These are pre-created in the secure Wolfi base, but we ensure they are ready here.
RUN set -eux; \
    mkdir -p "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" "$ZOO_LOG_DIR"; \
    chown -R 1000:0 "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" "$ZOO_LOG_DIR"; \
    chmod -R ug+w "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" "$ZOO_LOG_DIR"

ARG SHORT_DISTRO_NAME=zookeeper-3.8.6
ARG DISTRO_NAME=apache-zookeeper-3.8.6-bin

COPY zookeeper-assembly/target/$DISTRO_NAME.tar.gz /

# Untar Distro and clean up
RUN set -eux; \
    tar -zxf "$DISTRO_NAME.tar.gz"; \
    mv "$DISTRO_NAME/conf/"* "$ZOO_CONF_DIR"; \
    rm -rf "$DISTRO_NAME.tar.gz" "$DISTRO_NAME.tar.gz.asc"; \
    chown -R 1000:0 "/$DISTRO_NAME"

WORKDIR /$DISTRO_NAME
VOLUME ["$ZOO_DATA_DIR", "$ZOO_DATA_LOG_DIR", "$ZOO_LOG_DIR"]

EXPOSE 2181 2888 3888 8080

ENV PATH=$PATH:/$DISTRO_NAME/bin \
    ZOOCFGDIR=$ZOO_CONF_DIR

COPY docker-entrypoint.sh /

RUN mkdir -p /etc/confluent/docker
COPY --chown=1000:0 run.sh /etc/confluent/docker/run
RUN chmod 755 /etc/confluent/docker/run

USER 1000

CMD ["/etc/confluent/docker/run"]
