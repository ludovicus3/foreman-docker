#!/bin/sh

set -e

TRUSTSTORE=${TRUSTSTORE:-/etc/candlepin/certs/truststore}
KEYSTORE=${KEYSTORE:-/etc/candlepin/certs/keystore}

function add_key {
  local pkcs12=/tmp/pkcs12
  local alias=$1
  local cert=$2
  local key=$3
  local ca=$4

  openssl pkcs12 -export \
    -in $cert -inkey $key -out $pkcs12 \
    -name $alias -CAfile $ca -password pass:$KEYSTORE_PASSWORD

  keytool -importkeystore -noprompt \
    -srckeystore $pkcs12 -srcstorepass $KEYSTORE_PASSWORD \
    -destkeystore $KEYSTORE -deststorepass $KEYSTORE_PASSWORD \
    -srcalias $alias -destalias $alias -J-Dcom.redhat.fips=false

  rm -f $pkcs12
}

function add_trust {
  local alias=$1
  local certificate=$2

  keytool -import -noprompt -storetype pkcs12 -keystore $TRUSTSTORE \
    -alias $alias -file $certificate -storepass $TRUSTSTORE_PASSWORD \
    -J-Dcom.redhat.fips=false
}

add_trust candlepin-ca /var/run/secrets/tomcat/ca.crt
add_trust artemis-client /var/run/secrets/foreman/tls.crt

add_key tomcat /var/run/secrets/tomcat/tls.crt /var/run/secrets/tomcat/tls.key /var/run/secrets/tomcat/ca.crt

cp /var/run/secrets/ca/tls.crt /etc/candlepin/certs/candlepin-ca.crt
cp /var/run/secrets/ca/tls.key /etc/candlepin/certs/candlepin-ca.key

openssl x509 -noout -subject -nameopt rfc2253,sep_comma_plus_space < /var/run/secrets/foreman/tls.crt | sed 's/^subject/katelloUser/' > /opt/tomcat/conf/cert-users.properties

export POSTGRES_URL="jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT:-5432}/${POSTGRES_DATABASE:-candlepin}"
export POSTGRES_USER=${POSTGRES_USER:-candlepin}

envsubst < /etc/candlepin/candlepin.conf.template > /etc/candlepin/candlepin.conf

exec $@
