FROM eclipse-temurin:21.0.7_6-jre-alpine-3.21

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

# Backward-compatibility support for confluent users, groups, and directories
RUN set -eux; \
    adduser -u 1000 -S -G root appuser; \
    mkdir -p "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" "$ZOO_LOG_DIR"; \
    chown -R appuser:root "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" "$ZOO_LOG_DIR"; \
    chmod -R ug+w "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" "$ZOO_LOG_DIR"

# Install required packges
RUN set -eux; \
    apk update; \
    apk add --no-cache \
        ca-certificates \
        su-exec \
        gnupg \
        netcat-openbsd \
        bash \
        wget; \
    rm -rf /var/cache/apk/*; \
# Verify that su-exec binary works
    su-exec nobody true

ARG SHORT_DISTRO_NAME=zookeeper-3.8.4
ARG DISTRO_NAME=apache-zookeeper-3.8.4-bin

COPY zookeeper-assembly/target/$DISTRO_NAME.tar.gz /

# Untar Distro and clean up
RUN set -eux; \
    tar -zxf "$DISTRO_NAME.tar.gz"; \
    mv "$DISTRO_NAME/conf/"* "$ZOO_CONF_DIR"; \
    rm -rf "$DISTRO_NAME.tar.gz" "$DISTRO_NAME.tar.gz.asc"; \
    chown -R appuser:root "/$DISTRO_NAME"

WORKDIR $DISTRO_NAME
VOLUME ["$ZOO_DATA_DIR", "$ZOO_DATA_LOG_DIR", "$ZOO_LOG_DIR"]

EXPOSE 2181 2888 3888 8080

ENV PATH=$PATH:/$DISTRO_NAME/bin \
    ZOOCFGDIR=$ZOO_CONF_DIR

COPY docker-entrypoint.sh /

RUN mkdir /etc/confluent
RUN mkdir /etc/confluent/docker
COPY --chown=appuser:appuser run.sh /etc/confluent/docker/run
RUN chmod 755 /etc/confluent/docker/run

USER appuser

CMD ["/etc/confluent/docker/run"]
