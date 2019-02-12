#!/bin/bash

# Optional ENV variables:
# * Every env variable starting by `_KAFKA.` will be parsed:
#   e.g. _KAFKA.advertised.host.name=localshot will become advertised.host.name=localshot and will be written to server.properties

function add_config_param {
    prop_name=$(echo "$1" | tr "_" .)
    prop_value=$2
	echo "*** Setting '$prop_name=$prop_value' (parsed from $1)"
    if grep -q "^$prop_name" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s|($prop_name)=(.*)|\1=$prop_value|g" $KAFKA_HOME/config/server.properties
    else
        echo "$prop_name=$prop_value" >> $KAFKA_HOME/config/server.properties
    fi
}

function set_server_config {
    env | grep '_KAFKA'| awk -F'=' '{print $1}' | while read var; do add_config_param ${var:7} ${!var}; done
}

echo $'\n' >>  $KAFKA_HOME/config/server.properties

set_server_config

# debug auth request
sed -r -i "s|(log4j.logger.kafka.authorizer.logger)=(.*)|\1=DEBUG, authorizerAppender|g" $KAFKA_HOME/config/log4j.properties

# OCSP
if [ ! -z "$SSL_OCSP" ]; then
    echo -e "ocsp.enable=$SSL_OCSP" > $KAFKA_HOME/config/security.properties
    export KAFKA_OPTS="-Djava.security.debug=all -Dcom.sun.net.ssl.checkRevocation=$SSL_OCSP -Djava.security.properties=$KAFKA_HOME/config/security.properties $KAFKA_OPTS"
fi

# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
