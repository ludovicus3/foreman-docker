# Base container that is used for both building and running the app
FROM registry.access.redhat.com/ubi8 as base
ARG RUBY_VERSION="2.7"

RUN \
  dnf upgrade -y && \
  dnf module enable ruby:${RUBY_VERSION} -y && \
  dnf install ruby{,gems} rubygem-{rake,bundler} -y && \
  dnf clean all

ARG HOME=/smart-proxy
WORKDIR $HOME
RUN groupadd -r smart-proxy -f -g 0 && \
    useradd -u 1001 -r -g smart-proxy -d $HOME -s /sbin/nologin \
    -c "Smart Proxy Application User" smart-proxy && \
    chown -R 1001:0 $HOME && \
    chmod -R g=u ${HOME}

# Temp container that download gems/npms and compile assets etc
FROM base as builder

ARG SMART_PROXY_VERSION="develop"

ENV BUNDLER_SKIPPED_GROUPS="test development journald libvirt"

RUN \
  dnf install -y redhat-rpm-config git \
    gcc-c++ make bzip2 gettext tar \
    libxml2-devel libcurl-devel ruby-devel \ 
    krb5-devel && \
  dnf clean all

ARG HOME=/smart-proxy
USER 1001
WORKDIR $HOME

RUN \
  echo "Cloning from ${SMART_PROXY_VERSION}..." && \
  git clone --branch ${SMART_PROXY_VERSION} https://github.com/theforeman/smart-proxy.git ${HOME}

RUN bundle config set --local without "${BUNDLER_SKIPPED_GROUPS}" && \
  bundle config set --local clean true && \
  bundle config set --local path vendor && \
  bundle config set --local jobs 5 && \
  bundle config set --local retry 3
RUN bundle install && \
  bundle binstubs --all && \
  rm -rf vendor/ruby/*/cache/*.gem && \
  find vendor/ruby/*/gems -name "*.c" -delete && \
  find vendor/ruby/*/gems -name "*.o" -delete

USER 0
RUN chgrp -R 0 ${HOME} && \
    chmod -R g=u ${HOME}

USER 1001

FROM base

USER 0

ARG HOME=/smart-proxy

USER 1001
WORKDIR ${HOME}
COPY --from=builder --chown=1001:0 ${HOME} ${HOME}
COPY settings.yml ${HOME}/config/settings.yml
RUN find ${HOME}/config/settings.d -name "*.example" -exec sh -c 'mv "$1" "${1%.example}"' _ {} \;

RUN date -u > BUILD_TIME

# Start the main process.
CMD bundle exec bin/smart-proxy

EXPOSE 8080/tcp
EXPOSE 8443/tcp
