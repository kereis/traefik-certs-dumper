FROM ldez/traefik-certs-dumper:v2.7.0
LABEL maintainer="Humenius <contact@humenius.me>"

RUN \
    apk update && \
    apk add --no-cache \
        inotify-tools \
        util-linux \
        bash

COPY bin/dump /usr/bin/dump
COPY bin/healthcheck /usr/bin/healthcheck

RUN ["chmod", "+x", "/usr/bin/dump", "/usr/bin/healthcheck"]

HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
  CMD ["/usr/bin/healthcheck"]

VOLUME ["/traefik"]
VOLUME ["/output"]

ENTRYPOINT ["/usr/bin/dump"]
