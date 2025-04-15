#!/bin/bash

set -e

hocon() {
  /opt/puppetlabs/puppet/lib/ruby/vendor_gems/bin/hocon "$@"
}

if test -n "$PUPPETSERVER_PORT"; then
  hocon -f /etc/puppetlabs/puppetserver/conf.d/webserver.conf set webserver.ssl-port $PUPPETSERVER_PORT
  puppet config set serverport $PUPPETSERVER_PORT --section main
fi
