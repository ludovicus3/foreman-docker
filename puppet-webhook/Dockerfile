FROM docker.io/debian:bookworm-slim AS builder

RUN \
  set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends gcc ruby-dev make cmake pkg-config libssl-dev libc6-dev libssh2-1-dev; \
  gem install --no-doc r10k; \
  gem install --no-doc rugged -- --with-ssh

FROM docker.io/debian:bookworm-slim AS final

ADD https://github.com/voxpupuli/webhook-go/releases/download/v2.9.0/webhook-go_2.9.0_linux_amd64.deb webhook-go_2.9.0_linux_amd64.deb

COPY --from=builder /var/lib/gems/ /var/lib/gems/
COPY --from=builder /usr/local/bin/r10k /usr/local/bin/

RUN \
  set -eux; \
  groupadd -g 999 puppet; \
  useradd -m -u 999 -g puppet puppet; \
  dpkg -i webhook-go_2.9.0_linux_amd64.deb; \
  rm -f /webhook-go_2.9.0_linux_amd64.deb; \
  mkdir /etc/voxpupuli; \
  apt-get update; \
  apt-get upgrade -y; \
  apt-get install -y --no-install-recommends ruby ca-certificates netbase libssh2-1 libssl; \
  apt-get autoremove -y; \
  rm -rf /var/lib/apt/lists/*

ENV \
  WEBHOOK_CONFIG=/etc/voxpupuli/webhook.yaml

EXPOSE 4000

CMD [ "/usr/bin/webhook-go", "server" "--config ${WEBHOOK_CONFIG}" ]