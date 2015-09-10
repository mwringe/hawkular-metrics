#!/bin/bash
#
# Copyright 2014-2015 Red Hat, Inc. and/or its affiliates
# and other contributors as indicated by the @author tags.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

for args in "$@"
do
  case $args in
    --hawkular-metrics-keystore-password=*)
      HAWKULAR_METRICS_KEYSTORE_PASSWORD="${args#*=}"
    ;;
    --hawkular-metrics-truststore-password=*)
      HAWKULAR_METRICS_TRUSTSTORE_PASSWORD="${args#*=}"
    ;;
    --hawkular-metrics-keystore-alias=*)
      HAWKULAR_METRICS_KEYSTORE_ALIAS="${args#*=}"
    ;;
    --cassandra-keystore-password=*)
      CASSANDRA_KEYSTORE_PASSWORD="${args#*=}"
    ;;
    --cassandra-truststore-password=*)
      CASSANDRA_TRUSTSTORE_PASSWORD="${args#*=}"
    ;;
    --cassandra-keystore-alias=*)
      CASSANDRA_KEYSTORE_ALIAS="${args#*=}"
    ;;
    --dname=*)
      DNAME="${args#*=}"
    ;;
    --empty-dname)
      DNAME="CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown"
    ;;
    --generate-passwords)
      GENERATE_PASSWORDS=true
    ;;

  esac
done

if [ "$GENERATE_PASSWORDS" ]; then
   echo "Generating randomized passwords for the Hawkular Metrics and Cassandra keystores and truststores"
   HAWKULAR_METRICS_KEYSTORE_PASSWORD=`cat /dev/urandom | tr -dc _A-Z-a-z-0-9 | head -c15`
   HAWKULAR_METRICS_TRUSTSTORE_PASSWORD=`cat /dev/urandom | tr -dc _A-Z-a-z-0-9 | head -c15`
   CASSANDRA_KEYSTORE_PASSWORD=`cat /dev/urandom | tr -dc _A-Z-a-z-0-9 | head -c15`
   CASSANDRA_TRUSTSTORE_PASSWORD=`cat /dev/urandom | tr -dc _A-Z-a-z-0-9 | head -c15`
fi

if [ -z "$HAWKULAR_METRICS_KEYSTORE_PASSWORD" ]; then
  read -p "Please enter the Hawkular Metrics keystore password: " -s HAWKULAR_METRICS_KEYSTORE_PASSWORD
  echo
fi

if [ -z "$HAWKULAR_METRICS_TRUSTSTORE_PASSWORD" ]; then
  read -p "Please enter the Hawkular Metrics truststore password: " -s HAWKULAR_METRICS_TRUSTSTORE_PASSWORD
  echo
fi

if [ -z "$CASSANDRA_KEYSTORE_PASSWORD" ]; then
  read -p "Please enter the Cassandra keystore password: " -s CASSANDRA_KEYSTORE_PASSWORD
  echo
fi

if [ -z "$CASSANDRA_TRUSTSTORE_PASSWORD" ]; then
  read -p "Please enter the Cassandra truststore password: " -s CASSANDRA_TRUSTSTORE_PASSWORD
  echo
fi

if [ -z "$HAWKULAR_METRICS_KEYSTORE_ALIAS" ]; then
  HAWKULAR_METRICS_KEYSTORE_ALIAS="hawkular-metrics"
fi

if [ -z "$CASSANDRA_KEYSTORE_ALIAS" ]; then
  CASSANDRA_KEYSTORE_ALIAS="cassandra"
fi

echo
echo "Creating the Hawkular-Metrics Keystore"
if [ -z "$DNAME" ]; then
  keytool -genkey -noprompt -alias $HAWKULAR_METRICS_KEYSTORE_ALIAS -keyalg RSA -keystore hawkular-metrics.keystore \
          -keypass $HAWKULAR_METRICS_KEYSTORE_PASSWORD -storepass $HAWKULAR_METRICS_KEYSTORE_PASSWORD
else
  keytool -genkey -noprompt -alias $HAWKULAR_METRICS_KEYSTORE_ALIAS -keyalg RSA -keystore hawkular-metrics.keystore \
          -keypass $HAWKULAR_METRICS_KEYSTORE_PASSWORD -storepass $HAWKULAR_METRICS_KEYSTORE_PASSWORD \
          -dname "$DNAME"
fi

echo
echo "Creating the Cassandra Keystore"
if [ -z "$DNAME" ]; then
  keytool -noprompt -genkey -alias $CASSANDRA_KEYSTORE_ALIAS -keyalg RSA -keystore cassandra.keystore \
          -keypass $CASSANDRA_KEYSTORE_PASSWORD -storepass $CASSANDRA_KEYSTORE_PASSWORD
else
  keytool -noprompt -genkey -alias $CASSANDRA_KEYSTORE_ALIAS -keyalg RSA -keystore cassandra.keystore \
          -keypass $CASSANDRA_KEYSTORE_PASSWORD -storepass $CASSANDRA_KEYSTORE_PASSWORD \
          -dname "$DNAME"
fi

echo
echo "Creating the Hawkular Metrics Certificate"
keytool -noprompt -export -alias $HAWKULAR_METRICS_KEYSTORE_ALIAS -file hawkular-metrics.cert -keystore hawkular-metrics.keystore -storepass $HAWKULAR_METRICS_KEYSTORE_PASSWORD

echo
echo "Creating the Cassandra Certificate"
keytool -noprompt -export -alias $CASSANDRA_KEYSTORE_ALIAS -file cassandra.cert -keystore cassandra.keystore -storepass $CASSANDRA_KEYSTORE_PASSWORD

echo
echo "Importing the Hawkular Metrics certificate into the Cassandra Truststore"
keytool -noprompt -import -v -trustcacerts -alias $HAWKULAR_METRICS_KEYSTORE_ALIAS -file hawkular-metrics.cert -keystore cassandra.truststore -trustcacerts -storepass $CASSANDRA_TRUSTSTORE_PASSWORD

echo
echo "Importing the Cassandra certificate into the Hawkular Metrics Truststore"
keytool -noprompt -import -v -trustcacerts -alias $CASSANDRA_KEYSTORE_ALIAS -file cassandra.cert -keystore hawkular-metrics.truststore -trustcacerts -storepass $HAWKULAR_METRICS_TRUSTSTORE_PASSWORD

echo
echo "Importing the Cassandra certificate into the Cassandra Truststore"
keytool -noprompt -import -v -trustcacerts -alias $CASSANDRA_KEYSTORE_ALIAS -file cassandra.cert -keystore cassandra.truststore -trustcacerts -storepass $CASSANDRA_TRUSTSTORE_PASSWORD

echo
echo "Creating the Hawkular Metrics Secrets configuration json file"
cat > hawkular-metrics-secrets.json <<EOF
    {
      "apiVersion": "v1",
      "kind": "Secret",
      "metadata":
      { "name": "hawkular-metrics-secrets" },
      "data":
      {
        "hawkular-metrics.keystore": "$(base64 -w 0 hawkular-metrics.keystore)",
        "hawkular-metrics.keystore.password": "$(base64 <<< `echo $HAWKULAR_METRICS_KEYSTORE_PASSWORD`)",
        "hawkular-metrics.truststore": "$(base64 -w 0 hawkular-metrics.truststore)",
        "hawkular-metrics.truststore.password": "$(base64 <<< `echo $HAWKULAR_METRICS_TRUSTSTORE_PASSWORD`)",
        "hawkular-metrics.keystore.alias": "$(base64 <<< `echo $HAWKULAR_METRICS_KEYSTORE_ALIAS`)"
      }
    }
EOF

echo
echo "Creating the Hawkular Metrics Certificate Secrets configuration json file"
cat > hawkular-metrics-certificate.json <<EOF
    {
      "apiVersion": "v1",
      "kind": "Secret",
      "metadata":
      { "name": "hawkular-metrics-certificate" },
      "data":
      {
        "hawkular-metrics.certificate": "$(base64 -w 0 hawkular-metrics.cert)"
      }
    }
EOF


echo
echo "Creating the Cassandra Secrets configuration file"
cat > cassandra-secrets.json <<EOF
    {
      "apiVersion": "v1",
      "kind": "Secret",
      "metadata":
      { "name": "hawkular-cassandra-secrets" },
      "data":
      {
        "cassandra.keystore": "$(base64 -w 0 cassandra.keystore)",
        "cassandra.keystore.password": "$(base64 <<< `echo $CASSANDRA_KEYSTORE_PASSWORD`)",
        "cassandra.keystore.alias": "$(base64 <<< `echo $CASSANDRA_KEYSTORE_ALIAS`)",
        "cassandra.truststore": "$(base64 -w 0 cassandra.truststore)",
        "cassandra.truststore.password": "$(base64 <<< `echo $CASSANDRA_TRUSTSTORE_PASSWORD`)"
      }
    }
EOF

echo
echo "Creating the Cassandra Certificate Secrets configuration json file"
cat > cassandra-certificate.json <<EOF
    {
      "apiVersion": "v1",
      "kind": "Secret",
      "metadata":
      { "name": "hawkular-cassandra-certificate" },
      "data":
      {
        "cassandra.certificate": "$(base64 -w 0 cassandra.cert)"
      }
    }
EOF

