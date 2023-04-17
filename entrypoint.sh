#!/bin/bash
set -e

export PATH=~/bin:${GEM_HOME}/bin:${PATH}
export DYNFLOW_SIDEKIQ_SCRIPT=/home/foreman/extras/dynflow-sidekiq.rb
export BIND_HOST=0.0.0.0

case "$@" in
  "orchestrator")
    bundle exec sidekiq -e ${RAILS_ENV} -r ${DYNFLOW_SIDEKIQ_SCRIPT} -c 1 -q dynflow_orchestrator
    ;;
  "worker")
    bundle exec sidekiq -e ${RAILS_ENV} -r ${DYNFLOW_SIDEKIQ_SCRIPT} -c 1 -q ${DYNFLOW_QUEUE}
    ;;
  "foreman")
    bundle exec bin/rake db:migrate
    bundle exec bin/rake db:seed
    bundle exec bin/rails server -b ${BIND_HOST}
    ;;
  *)
    exec $@
    ;;
esac
