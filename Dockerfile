FROM ldez/traefik-certs-dumper:v2.7.0
LABEL maintainer="Humenius <contact@humenius.me>"

RUN apk --no-cache add inotify-tools util-linux bash

COPY run.sh /

RUN ["chmod", "+x", "/run.sh"]

VOLUME ["/traefik"]
VOLUME ["/output"]

ENTRYPOINT ["/run.sh"]
