FROM quay.io/centos/centos:stream8 as base
ARG RUBY_VERSION="2.7"
ARG NODEJS_VERSION="12"

ENV FOREMAN_FQDN=foreman.example.com
ENV FOREMAN_DOMAIN=example.com

RUN \
  dnf upgrade -y && \
  dnf module enable ruby:${RUBY_VERSION} nodejs:${NODEJS_VERSION} -y && \
  dnf install -y postgresql-libs ruby{,gems} rubygem-{rake,bundler} npm nc hostname redhat-rpm-config git git-lfs sudo gcc-c++ make bzip2 gettext tar libxml2-devel libcurl-devel ruby-devel postgresql-devel && \
  rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8 && \
  rpm -i https://dl.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/q/qpid-proton-c-0.37.0-1.el8.x86_64.rpm && \
  rpm -i https://dl.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/q/qpid-proton-c-devel-0.37.0-1.el8.x86_64.rpm && \
  dnf clean all

ARG FOREMAN=/foreman
WORKDIR $FOREMAN

RUN \
  groupadd -r foreman -f -g 0 && \
  useradd -u 1001 -r -g foreman -d $FOREMAN -s /sbin/nologin -c "Foreman Application User" foreman && \
  chown -R 1001:0 $FOREMAN && \
  chmod -R g=u $FOREMAN

ARG FOREMAN_VERSION="develop"

ENV RAILS_ENV=production
ENV FOREMAN_APIPIE_LANGS=en
ENV BUNDLER_SKIPPED_GROUPS="test development openid libvirt journald facter console"
ENV DATABASE_URL=nulldb://nohost
USER 1001

RUN \
  echo "Cloning from ${FOREMAN_VERSION}..." && \
  git clone --branch ${FOREMAN_VERSION} https://github.com/theforeman/foreman.git .

COPY --chown=1001:0 bundler.d bundler.d/

RUN \
  bundle config set --local without "${BUNDLER_SKIPPED_GROUPS}" && \
  bundle config set --local clean true && \
  bundle config set --local path vendor && \
  bundle config set --local jobs 5 && \
  bundle config set --local retry 3
RUN \
  bundle install && \
  bundle binstubs --all
RUN \
  make -C locale all-mo && \
  mv -v db/schema.rb.nulldb db/schema.rb && \
  bundle exec rake assets:clean assets:precompile

RUN \
  npm install --no-optional && \
  ./node_modules/webpack/bin/webpack.js --config config/webpack.config.js && \
  npm run analyze

USER 0
COPY --chown=0:0 entrypoint.sh /

RUN \
    # add user and configure it
    useradd -u 10001 -G wheel,root -d /home/user --shell /bin/bash -m user && \
    # Setup $PS1 for a consistent and reasonable prompt
    echo "export PS1='\W \`git branch --show-current 2>/dev/null | sed -r -e \"s@^(.+)@\(\1\) @\"\`$ '" >> /home/user/.bashrc && \
    # Copy the global git configuration to user config as global /etc/gitconfig
    #  file may be overwritten by a mounted file at runtime
    cp /etc/gitconfig /home/user/.gitconfig && \
    # Set permissions on /etc/passwd and /home to allow arbitrary users to write
    chgrp -R 0 /home && \
    chmod -R g=u /etc/passwd /etc/group /home && \
    chmod +x /entrypoint.sh

USER 10001
ENV HOME=/home/user
WORKDIR /projects
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["tail", "-f", "/dev/null"]
