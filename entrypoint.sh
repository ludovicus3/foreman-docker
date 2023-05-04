#!/bin/bash
set -e

export PATH=~/bin:${GEM_HOME}/bin:${PATH}
export DYNFLOW_SIDEKIQ_SCRIPT=/home/foreman/extras/dynflow-sidekiq.rb

if [ ! -d "${HOME}" ]; then
  mkdir -p "${HOME}"
fi

if [ -w "${HOME}" ] && [ ! -f "${HOME}"/.bashrc ]; then
  echo "PS1='[\u@\h \W]\$ '" > "${HOME}"/.bashrc
fi

if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-user}:x:$(id -u):0:${USER_NAME:-user} user:${HOME}:/bin/bash" >> /etc/passwd
    echo "${USER_NAME:-user}:x:$(id -u):" >> /etc/group
  fi
fi

case "$@" in
  "orchestrator")
    bundle exec sidekiq -e ${RAILS_ENV} -r ${DYNFLOW_SIDEKIQ_SCRIPT} -c 1 -q dynflow_orchestrator
    ;;
  "worker")
    bundle exec sidekiq -e ${RAILS_ENV} -r ${DYNFLOW_SIDEKIQ_SCRIPT} -c 1 -q ${DYNFLOW_QUEUE}
    ;;
  "foreman")
    bundle exec bin/rake db:migrate
    bundle exec bin/rails server
    ;;
  *)
    exec $@
    ;;
esac
