#!/bin/bash

set -eux

pid=0

sigterm_handler() {
  echo "Catching SIGTERM"
  if [ $pid -ne 0 ]; then
    echo "sigterm_handler for PID '${pid}' triggered"
    kill -15 "$pid"
    wait "$pid"
  fi
  exit 143
}

## Setup signal trap
# on callback execute the specified handler
trap sigterm_handler SIGTERM

## Initialization
for script in /docker-entrypoint.d/*.sh; do
  echo "Running $script"
  "$script"
done

## Start Process
echo "Starting Puppetserver"
# run process in background and record PID
/opt/puppetlabs/bin/puppetserver "$@" &
pid="$!"

## Wait forever until app dies
wait "$pid"
return_code="$?"

# echo the return code of the application
exit $return_code