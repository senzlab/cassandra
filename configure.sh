#!/bin/bash
CASSANDRA_HOME=/opt/cassandra
CASSANDRA_HOST="$(hostname --ip-address)"

sed -ri 's/^(# )?('"listen_address"':).*/\2 '"$CASSANDRA_HOST"'/' "$CASSANDRA_HOME/conf/cassandra.yaml"
sed -ri 's/^(# )?('"rpc_address"':).*/\2 '"$CASSANDRA_HOST"'/' "$CASSANDRA_HOME/conf/cassandra.yaml"
sed -ri 's/^(# )?('"broadcast_address"':).*/\2 '"$CASSANDRA_HOST"'/' "$CASSANDRA_HOME/conf/cassandra.yaml"
sed -ri 's/^(# )?('"broadcast_rpc_address"':).*/\2 '"$CASSANDRA_HOST"'/' "$CASSANDRA_HOME/conf/cassandra.yaml"

# config cassandra seeds
if [ -z "$CASSANDRA_SEEDS" ]; then
	CASSANDRA_SEEDS=$CASSANDRA_HOST
fi
sed -ri 's/(- seeds:).*/\1 "'"$CASSANDRA_SEEDS"'"/' "$CASSANDRA_HOME/conf/cassandra.yaml"

exec "$@"
