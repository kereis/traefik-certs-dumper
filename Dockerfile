FROM docker:19.03.8
LABEL maintainer="Humenius <contact@humenius.me>"

RUN apk --no-cache add inotify-tools util-linux bash

COPY run.sh /
COPY bin/healthcheck /usr/bin/healthcheck

RUN ["chmod", "+x", "/run.sh", "/usr/bin/healthcheck"]

HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
  CMD ["/usr/bin/healthcheck"]

COPY --from=ldez/traefik-certs-dumper:v2.7.0 /usr/bin/traefik-certs-dumper /usr/bin/traefik-certs-dumper

VOLUME ["/traefik"]
VOLUME ["/output"]

ENTRYPOINT ["/run.sh"]
