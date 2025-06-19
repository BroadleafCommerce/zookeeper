#!/bin/bash

set -e

if [ -v KAFKA_HEAP_OPTS ]; then
  extra=""
    if [ -v JVMFLAGS ]; then
      extra="$JVMFLAGS"
    fi
    extra+=" $KAFKA_HEAP_OPTS"
  export JVMFLAGS="$extra"
fi

if [ -v KAFKA_OPTS ]; then
  extra=""
    if [ -v JVMFLAGS ]; then
      extra="$JVMFLAGS"
    fi
    extra+=" $KAFKA_OPTS"
  export JVMFLAGS="$extra"
fi

if [ -v ZOOKEEPER_CLIENT_PORT ]; then
  extra=""
  if [ -v ZOO_CFG_EXTRA ]; then
    extra="$ZOO_CFG_EXTRA"
  fi
  extra+=" clientPort=$ZOOKEEPER_CLIENT_PORT"
  export ZOO_CFG_EXTRA="$extra"
fi

if [ -v ZOOKEEPER_SECURE_CLIENT_PORT ]; then
  extra=""
  if [ -v ZOO_CFG_EXTRA ]; then
    extra="$ZOO_CFG_EXTRA"
  fi
  extra+=" secureClientPort=$ZOOKEEPER_SECURE_CLIENT_PORT"
  export ZOO_CFG_EXTRA="$extra"
fi

if [ -v ZOOKEEPER_TICK_TIME ]; then
  export ZOO_TICK_TIME="$ZOOKEEPER_TICK_TIME"
fi

if [ -v ZOOKEEPER_INIT_LIMIT ]; then
  export ZOO_INIT_LIMIT="$ZOOKEEPER_INIT_LIMIT"
fi

if [ -v ZOOKEEPER_SYNC_LIMIT ]; then
  export ZOO_SYNC_LIMIT="$ZOOKEEPER_SYNC_LIMIT"
fi

if [ -v ZOOKEEPER_MAX_CLIENT_CNXNS ]; then
  export ZOO_MAX_CLIENT_CNXNS="$ZOOKEEPER_MAX_CLIENT_CNXNS"
fi

if [ -v ZOOKEEPER_STANDALONE_ENABLED ]; then
  export ZOO_STANDALONE_ENABLED="$ZOOKEEPER_STANDALONE_ENABLED"
fi

if [ -v ZOOKEEPER_ADMINSERVER_ENABLED ]; then
  export ZOO_ADMINSERVER_ENABLED="$ZOOKEEPER_ADMINSERVER_ENABLED"
fi

if [ -v ZOOKEEPER_AUTOPURGE_PURGEINTERVAL ]; then
  export ZOO_AUTOPURGE_PURGEINTERVAL="$ZOOKEEPER_AUTOPURGE_PURGEINTERVAL"
fi

if [ -v ZOOKEEPER_AUTOPURGE_SNAPRETAINCOUNT ]; then
  export ZOO_AUTOPURGE_SNAPRETAINCOUNT="$ZOOKEEPER_AUTOPURGE_SNAPRETAINCOUNT"
fi

if [ -v ZOOKEEPER_4LW_COMMANDS_WHITELIST ]; then
  export ZOO_4LW_COMMANDS_WHITELIST="$ZOOKEEPER_4LW_COMMANDS_WHITELIST"
fi

if [ -v ZOOKEEPER_SERVER_ID ]; then
  export ZOO_MY_ID="$ZOOKEEPER_SERVER_ID"
fi

if [ -v ZOOKEEPER_SERVERS ]; then
  export ZOO_SERVERS="$ZOOKEEPER_SERVERS"
fi

# Allow the container to be started with `--user`
if [[ "$1" = 'zkServer.sh' && "$(id -u)" = '0' ]]; then
    chown -R zookeeper "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR" "$ZOO_LOG_DIR"
    exec su-exec zookeeper "$0" "$@"
fi

# Generate the config only if it doesn't exist
if [[ ! -f "$ZOO_CONF_DIR/zoo.cfg" ]]; then
    CONFIG="$ZOO_CONF_DIR/zoo.cfg"
    {
        echo "dataDir=$ZOO_DATA_DIR"
        echo "dataLogDir=$ZOO_DATA_LOG_DIR"

        echo "tickTime=$ZOO_TICK_TIME"
        echo "initLimit=$ZOO_INIT_LIMIT"
        echo "syncLimit=$ZOO_SYNC_LIMIT"

        echo "autopurge.snapRetainCount=$ZOO_AUTOPURGE_SNAPRETAINCOUNT"
        echo "autopurge.purgeInterval=$ZOO_AUTOPURGE_PURGEINTERVAL"
        echo "maxClientCnxns=$ZOO_MAX_CLIENT_CNXNS"
        echo "standaloneEnabled=$ZOO_STANDALONE_ENABLED"
        echo "admin.enableServer=$ZOO_ADMINSERVER_ENABLED"
    } >> "$CONFIG"
    if [[ -z $ZOO_SERVERS ]]; then
      ZOO_SERVERS="server.1=localhost:2888:3888;2181"
    fi

    for server in $ZOO_SERVERS; do
        echo "$server" >> "$CONFIG"
    done

    if [[ -n $ZOO_4LW_COMMANDS_WHITELIST ]]; then
        echo "4lw.commands.whitelist=$ZOO_4LW_COMMANDS_WHITELIST" >> "$CONFIG"
    fi

    for cfg_extra_entry in $ZOO_CFG_EXTRA; do
        echo "$cfg_extra_entry" >> "$CONFIG"
    done
fi

# Write myid only if it doesn't exist
if [[ ! -f "$ZOO_DATA_DIR/myid" ]]; then
    echo "${ZOO_MY_ID:-1}" > "$ZOO_DATA_DIR/myid"
fi

exec "$@"
