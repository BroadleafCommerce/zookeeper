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

EXCLUDE_VARS=(
  "ZOOKEEPER_CLIENT_PORT"
  "ZOOKEEPER_SECURE_CLIENT_PORT"
  "ZOOKEEPER_SERVERS"
)

for VAR in $(env)
do
  # Extract the variable name (without the value)
  VAR_NAME=$(echo "$VAR" | cut -d= -f1)

  # Check if variable starts with KAFKA_ and is not in the exclude list
  if [[ $VAR_NAME =~ ^ZOOKEEPER_ ]]; then
    # Check if the variable is in the exclude list
    EXCLUDED=false
    for EXCLUDE in "${EXCLUDE_VARS[@]}"; do
      if [[ $VAR_NAME == "$EXCLUDE" ]]; then
        EXCLUDED=true
        break
      fi
    done

    # Process only if not excluded
    if [[ $EXCLUDED == false ]]; then
      KEY_PART=$(echo "$VAR" | sed -r 's/ZOOKEEPER_([^=]*)=.*/\1/g' | sed -r 's/\.\.+/_/g')
      KAFKA_PROP_KEY="ZOO_$KEY_PART"

      # Extract the value
      KAFKA_PROP_VALUE=$(echo "$VAR" | sed -r 's/ZOOKEEPER_[^=]*=(.*)/\1/g')
      declare -x "$KAFKA_PROP_KEY"="$KAFKA_PROP_VALUE"
    fi
  fi
done

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
    } >> "$CONFIG"
    
    if [[ -n "$ZOOKEEPER_SERVERS" ]]; then
      # Handle Confluent ZOOKEEPER_SERVERS ENV syntax if present
      # Normalize delimiters: replace all semicolons and spaces with a newline
      SERVERS=$(echo "$ZOOKEEPER_SERVERS" | tr '; ' '\n' | grep -v '^$')

      INDEX=1
      while IFS= read -r SERVER; do
        echo "server.${INDEX}=${SERVER}" >> "$CONFIG"
        ((INDEX++))
      done <<< "$SERVERS"
    else 
      # Handle default ZOO_SERVERS ENV syntax
      if [[ -z $ZOO_SERVERS ]]; then
        ZOO_SERVERS="server.1=localhost:2888:3888;2181"
      fi

      for server in $ZOO_SERVERS; do
          echo "$server" >> "$CONFIG"
      done    
    fi

    if [[ -n $ZOO_4LW_COMMANDS_WHITELIST ]]; then
        echo "4lw.commands.whitelist=$ZOO_4LW_COMMANDS_WHITELIST" >> "$CONFIG"
    fi

    for cfg_extra_entry in $ZOO_CFG_EXTRA; do
        echo "$cfg_extra_entry" >> "$CONFIG"
    done
fi

# Write myid only if it doesn't exist
if [[ ! -f "$ZOO_DATA_DIR/myid" ]]; then

    if [[ -n $ZOOKEEPER_SERVER_ID ]]; then
        # Handle Confluent ZOOKEEPER_SERVER_ID ENV syntax if present
        echo "${ZOOKEEPER_SERVER_ID:-1}" > "$ZOO_DATA_DIR/myid"  
    else
        echo "${ZOO_MY_ID:-1}" > "$ZOO_DATA_DIR/myid"        
    fi    

fi

exec "$@"
