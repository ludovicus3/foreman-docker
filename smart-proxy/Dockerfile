# Base container that is used for both building and running the app
ARG RUBY_VERSION="3.1"
FROM docker.io/ruby:${RUBY_VERSION}-slim-bookworm AS base

RUN \
  set -eux; \
  export PACKAGES="libxml2 libkrb5-3"; \
  apt-get update; \
  apt-get upgrade -y; \
  apt-get install -y --no-install-recommends ${PACKAGES}; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*

ENV HOME=/smart-proxy
WORKDIR $HOME
RUN \
  set -eux; \
  groupadd -r smart-proxy -f -g 0; \
  useradd -u 1001 -g smart-proxy -d ${HOME} -s /sbin/nologin -c "Smart Proxy Daemon User" smart-proxy; \
  chown -R 1001:0 ${HOME}; \
  chmod -R g=u ${HOME}

# Temp container that download gems/npms and compile assets etc
FROM base as builder

ARG SMART_PROXY_VERSION="develop"

ENV BUNDLER_SKIPPED_GROUPS="test development journald libvirt"

RUN \
  set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends git g++ make bzip2 gettext tar libxml2-dev libkrb5-dev; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*

ENV HOME=/smart-proxy
USER 1001
WORKDIR $HOME

RUN \
  echo "Cloning from ${SMART_PROXY_VERSION}..."; \
  git clone --branch ${SMART_PROXY_VERSION} https://github.com/theforeman/smart-proxy.git ${HOME}; \
  rm -rf ${HOME}/.git

RUN \
  set -eux; \
  bundle config set --local without "${BUNDLER_SKIPPED_GROUPS}"; \
  bundle config set --local clean true; \
  bundle config set --local path vendor; \
  bundle config set --local jobs 5; \
  bundle config set --local retry 3
RUN \
  set -eux; \
  bundle install; \
  bundle binstubs --all; \
  rm -rf vendor/ruby/*/cache/*.gem; \
  find vendor/ruby/*/gems -name "*.c" -delete; \
  find vendor/ruby/*/gems -name "*.o" -delete

USER 0
RUN \
  set -eux; \
  chgrp -R 0 ${HOME}; \
  chmod -R g=u ${HOME}

USER 1001

RUN find ${HOME}/config/settings.d -name "*.example" -exec sh -c 'mv "$1" "${1%.example}"' _ {} \;

FROM base

USER 1001

ENV BUNDLER_SKIPPED_GROUPS="test development journald libvirt"
ENV HOME=/smart-proxy

WORKDIR ${HOME}

COPY --from=builder --chown=1001:0 ${HOME} ${HOME}
COPY settings.yml ${HOME}/config/settings.yml

RUN \
  set -eux; \
  bundle config set --local without "${BUNDLER_SKIPPED_GROUPS}"; \
  bundle config set --local clean true; \
  bundle config set --local path vendor; \
  bundle config set --local jobs 5; \
  bundle config set --local retry 3

RUN date -u > BUILD_TIME

# Start the main process.
CMD bundle exec bin/smart-proxy

EXPOSE 8080/tcp
EXPOSE 8443/tcp
