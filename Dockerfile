FROM ldez/traefik-certs-dumper:v2.7.0

LABEL maintainer="Humenius <contact@humenius.me>"

RUN \
    apk update && \
    apk add --no-cache \
        inotify-tools \
        util-linux \
        bash

COPY run.sh /

RUN ["chmod", "+x", "/run.sh"]

VOLUME ["/traefik"]
VOLUME ["/output"]

ENTRYPOINT ["/run.sh"]
