FROM docker.io/debian:bookworm-slim AS builder

RUN \
  set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends gcc ruby-dev make cmake pkg-config libssl-dev libc6-dev libssh2-1-dev; \
  gem install --no-doc r10k; \
  gem install --no-doc rugged -- --with-ssh

FROM docker.io/debian:bookworm-slim AS final

ENV PUPPETSERVER_JAVA_ARGS="-Xms1024m -Xmx1024m" \
    PATH=$PATH:/opt/puppetlabs/server/bin:/opt/puppetlabs/puppet/bin:/opt/puppetlabs/bin \
    SSLDIR=/etc/puppetlabs/puppet/ssl \
    LOGDIR=/var/log/puppetlabs/puppetserver \
    PUPPETSERVER_HOSTNAME="" \
    CERTNAME="" \
    DNS_ALT_NAMES="" \
    PUPPETSERVER_PORT=8140 \
    AUTOSIGN="/etc/puppetlabs/puppet/autosign.conf { mode = 0664 }" \
    PUPPETSERVER_MAX_ACTIVE_INSTANCES=1 \
    PUPPETSERVER_MAX_REQUESTS_PER_INSTANCE=0 \
    CA_ENABLED=true \
    CA_HOSTNAME=puppet \
    CA_PORT=8140 \
    CA_ALLOW_SUBJECT_ALT_NAMES=false \
    CA_TTL=157680000 \
    ENVIRONMENT_PATH=/etc/puppetlabs/code/environments \
    HIERACONFIG='$confdir/hiera.yaml' \
    EXTERNAL_NODES="/etc/puppetlabs/puppet/node.rb"

ADD https://apt.puppet.com/puppet-release-bookworm.deb /puppet-release-bookworm.deb

COPY docker-entrypoint.sh /
COPY docker-entrypoint.d /docker-entrypoint.d
COPY --from=builder /var/lib/gems/ /var/lib/gems/
COPY --from=builder /usr/local/bin/r10k /usr/local/bin/

RUN \
  set -eux; \
  groupadd -g 999 puppet; \
  useradd -m -u 999 -g puppet puppet; \
  dpkg -i puppet-release-bookworm.deb; \
  rm -f /puppet-release-bookworm.deb; \
  chmod +x /docker-entrypoint.sh /docker-entrypoint.d/*.sh; \
  apt-get update; \
  apt-get upgrade; \
  apt-get install -y --no-install-recommends ca-certificates openjdk-17-jre-headless puppetserver dumb-init; \
  apt-get autoremove -y; \
  rm -rf /var/lib/apt/lists/*

ADD https://raw.githubusercontent.com/theforeman/puppet-puppetserver_foreman/refs/head/master/files/enc.rb /etc/puppetlabs/puppet/node.rb
ADD https://raw.githubusercontent.com/theforeman/puppet-puppetserver_foreman/refs/head/master/files/reports.rb /opt/puppetlabs/puppet/lib/ruby/vendor_ruby/puppet/reports/foreman.rb

COPY logback.xml request-logging.xml /etc/puppetlabs/puppetserver/
COPY foreman.yaml.erb /etc/puppetlabs/puppet/foreman.yaml

RUN \
  mkdir -p /opt/puppetlabs/server/data/puppetserver/yaml/{facts,foreman,node}

USER 999

ENTRYPOINT ["dumb-init", "/docker-entrypoint.sh"]
CMD ["foreground"]