#!/bin/bash

WORKDIR=/tmp/work

dump() {
	log "Clearing dumping directory"
	rm -rf $WORKDIR/*

	log "Dumping certificates"
	traefik-certs-dumper file --version v2 --crt-name "cert" --crt-ext ".pem" --key-name "key" --key-ext ".pem" --domain-subdir --dest /tmp/work --source /traefik/acme.json > /dev/null

	if [[ -f /tmp/work/${DOMAIN}/cert.pem && -f /tmp/work/${DOMAIN}/key.pem && -f /output/cert.pem && -f /output/key.pem ]] && \
		diff -q ${WORKDIR}/${DOMAIN}/cert.pem /output/cert.pem >/dev/null && \
		diff -q ${WORKDIR}/${DOMAIN}/key.pem /output/key.pem >/dev/null ; \
	then
		log "Certificate and key still up to date, doing nothing"
	else
		log "Certificate or key differ, updating"
		mv ${WORKDIR}/${DOMAIN}/*.pem /output/
    restart_containers
	fi
}

restart_containers() {
	postfix_c=$(docker ps -qaf name=postfix-mailcow)
	dovecot_c=$(docker ps -qaf name=dovecot-mailcow)
	nginx_c=$(docker ps -qaf name=nginx-mailcow)

	log "`cat << EOF
	Following containers have been found:
	- Postfix: ${postfix_c}
	- Dovecot: ${dovecot_c}
	- Nginx: ${nginx_c}
	EOF`"
	log "Restarting containers now"
	
	docker restart ${postfix_c} ${dovecot_c} ${nginx_c}

	if [ $? -eq 0 ]; then
		log "Restarting containers was successful"
	else
		err "Something went wrong while restarting containers. Please check health of containers and consider restarting them manually."
	fi
}

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}

mkdir -p ${WORKDIR}
dump

while true; do
	inotifywait -qq -e modify /traefik/acme.json
	dump
done
