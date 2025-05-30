FROM alpine:3.22.0

RUN \
    apk update && \
    apk add --no-cache \
        --no-progress \
        inotify-tools \
        util-linux \
        bash \
        openssl \
        ca-certificates \
        tzdata && \
    rm -rf /var/cache/apk/*

COPY bin/dump.sh /usr/bin/dump
COPY bin/healthcheck.sh /usr/bin/healthcheck

RUN ["chmod", "+x", "/usr/bin/dump", "/usr/bin/healthcheck"]

COPY --from=ldez/traefik-certs-dumper:v2.10.0 /usr/bin/traefik-certs-dumper /usr/bin/traefik-certs-dumper

HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
  CMD ["/usr/bin/healthcheck"]

VOLUME ["/traefik"]
VOLUME ["/output"]

ENTRYPOINT ["/usr/bin/dump"]
