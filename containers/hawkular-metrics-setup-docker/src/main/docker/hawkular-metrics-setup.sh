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

echo "Starting up the one time Hawkular Metrics configuration pod."
echo
pushd $HAWKULAR_HOME

# Get the service account token
SERVICE_ACCOUNT_TOKEN_FILE=/var/run/secrets/kubernetes.io/serviceaccount/token

# Get the certificate used by the Kuberenetes Master
CA_CERTIFICATE=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

SERVICE_ACCOUNT_TOKEN=$(cat $SERVICE_ACCOUNT_TOKEN_FILE)

SECRET_URL="https://kubernetes.default.svc.cluster.local:443/api/v1/namespaces/default/secrets"

STATUS_COMMAND="curl --cacert $CA_CERTIFICATE -H \"Authorization: Bearer $SERVICE_ACCOUNT_TOKEN\" -L -s -o /dev/null -w \"%{http_code}\" $SECRET_URL"

SC_HAWKULAR_METRICS_SECRETS=`eval $STATUS_COMMAND/hawkular-metrics-secrets`
SC_HAWKULAR_METRICS_CERTIFICATE=`eval $STATUS_COMMAND/hawkular-metrics-certificiate`
SC_CASSANDRA_SECRETS=`eval $STATUS_COMMAND/hawkular-cassandra-secrets`
SC_CASSANDRA_CERTIFICATE=`eval $STATUS_COMMAND/hawkular-cassandra-certificate`

if [ $SC_HAWKULAR_METRICS_SECRETS -eq 404 ] && [ $SC_HAWKULAR_METRICS_CERTIFICATE -eq 404 ] && [ $SC_CASSANDRA_SECRETS -eq 404 ] && [ $SC_CASSANDRA_CERTIFICATE -eq 404 ]; then
  echo "None of the secrets currently exist. Creating them now"
  #Generate the secrets
  $HAWKULAR_HOME/generate-secrets.sh --generate-passwords --empty-dname

  curl --cacert $CA_CERTIFICATE -H "Authorization: Bearer $SERVICE_ACCOUNT_TOKEN" --data @hawkular-metrics-secrets.json -s -o /dev/null -X POST $SECRET_URL
  curl --cacert $CA_CERTIFICATE -H "Authorization: Bearer $SERVICE_ACCOUNT_TOKEN" --data @hawkular-metrics-certificate.json -s -o /dev/null -X POST $SECRET_URL
  curl --cacert $CA_CERTIFICATE -H "Authorization: Bearer $SERVICE_ACCOUNT_TOKEN" --data @cassandra-secrets.json -s -o /dev/null -X POST $SECRET_URL
  curl --cacert $CA_CERTIFICATE -H "Authorization: Bearer $SERVICE_ACCOUNT_TOKEN" --data @cassandra-certificate.json -s -o /dev/null -X POST $SECRET_URL
fi

echo
echo "Setup completed. Secrets should be ready to be consumed"
echo

popd
