#!/bin/bash

set -e

if [ -n "${EXTERNAL_NODES}" ]; then
  /opt/puppetlabs/bin/puppet config set external_nodes "${EXTERNAL_NODES}" --section server
  /opt/puppetlabs/bin/puppet config set node_terminus exec --section server
fi