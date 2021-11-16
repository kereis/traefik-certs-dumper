FROM ldez/traefik-certs-dumper:v2.7.0
LABEL maintainer="kereis <kreis-dev@gmx.net>"

RUN \
    apk update && \
    apk add --no-cache \
        inotify-tools \
        util-linux \
        bash \
        openssl

COPY bin/dump.sh /usr/bin/dump
COPY bin/healthcheck.sh /usr/bin/healthcheck

RUN ["chmod", "+x", "/usr/bin/dump", "/usr/bin/healthcheck"]

HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
  CMD ["/usr/bin/healthcheck"]

VOLUME ["/traefik"]
VOLUME ["/output"]

ENTRYPOINT ["/usr/bin/dump"]
