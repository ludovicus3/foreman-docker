#!/bin/bash
set -e

export PATH=~/bin:${GEM_HOME}/bin:${PATH}
export DYNFLOW_SIDEKIQ_SCRIPT=/home/foreman/extras/dynflow-sidekiq.rb
export RAILS_ENV=${RAILS_ENV:-production}

case "$1" in
  "orchestrator")
    bundle exec sidekiq \
      --environment ${RAILS_ENV} \
      --require ${DYNFLOW_SIDEKIQ_SCRIPT} \
      --concurrency 1 \
      --queue dynflow_orchestrator
    ;;
  "worker")
    bundle exec sidekiq \
      --environment ${RAILS_ENV} \
      --require ${DYNFLOW_SIDEKIQ_SCRIPT} \
      --concurrency ${CONCURRENCY:-$(nproc)} \
      --queue $2
    ;;
  "foreman")
    bundle exec bin/rake db:migrate
    bundle exec bin/rake db:seed
    bundle exec bin/rails server --binding ${BIND_HOST:-0.0.0.0}
    ;;
  *)
    exec $@
    ;;
esac
