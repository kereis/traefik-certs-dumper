#!/bin/bash

WORKDIR=/tmp/traefik-certs-dumper/


###############################################
####             DUMPING LOGIC             ####
###############################################

dump() {
	log "Clearing dumping directory"
	rm -rf $WORKDIR/*

	log "Dumping certificates"
	# traefik-certs-dumper file --version v2 --crt-name "cert" --crt-ext ".pem" --key-name "key" --key-ext ".pem" --domain-subdir --dest /tmp/work --source /traefik/acme.json > /dev/null

	# if [[ -f /tmp/work/${DOMAIN}/cert.pem && -f /tmp/work/${DOMAIN}/key.pem && -f /output/cert.pem && -f /output/key.pem ]] && \
	# 	diff -q ${WORKDIR}/${DOMAIN}/cert.pem /output/cert.pem >/dev/null && \
	# 	diff -q ${WORKDIR}/${DOMAIN}/key.pem /output/key.pem >/dev/null ; \
	# then
	# 	log "Certificate and key still up to date, doing nothing"
	# else
		log "Certificate or key differ, updating"
	#	mv ${WORKDIR}/${DOMAIN}/*.pem /output/
    
    if [ ! -z "${CONTAINERS#}" ]; then
      log "Trying to restart containers"
      restart_containers
    fi
	#fi
}

restart_containers() {
  for i in "${CONTAINERS[@]}"; do
    log "Looking up container with name ${i}"

    local found_container=$(docker ps -qaf name="${i}")
    if [ ! -z "${found_container}" ]; then
      log "Found '${found_container}'. Restarting now..."

      docker restart ${found_container}

      if [ $? -eq 0 ]; then
        log "Restarting container '${found_container}' was successful"
      else
        err "
        Something went wrong while restarting '${found_container}'
        Please check health of containers and consider restarting them manually.
        "
      fi
    else
      err "Container '${i}' could not be found. Omitting container..."
    fi
  done

  log "Container restarting process done."
}

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}



###############################################
####      COMMAND LINE ARGS PARSING        ####
###############################################

die() {
  local _ret=$2
  test -n "$_ret" || _ret=1
  test "$_PRINT_HELP" = yes && print_help >&2
  echo "$1" >&2
  exit ${_ret}
}


begins_with_short_option() {
  local first_option all_short_options='rh'
  first_option="${1:0:1}"
  test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

_arg_restart_containers=

print_help() {
  printf '%s\n' "traefik-certs-dumper bash script by Humenius <contact@humenius.me>"
  printf 'Usage: %s [-r|--restart-containers <arg>] [-h|--help]\n' "$0"
  printf '\t%s\n' "-r, --restart-containers: Restart containers passed as comma-separated container names (no default)"
  printf '\t%s\n' "-h, --help: Prints help"
}

parse_commandline() {
  while test $# -gt 0
  do
    _key="$1"
    case "$_key" in
      -r|--restart-containers)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_restart_containers="$2"
        shift
        ;;
      --restart-containers=*)
        _arg_restart_containers="${_key##--restart-containers=}"
        ;;
      -r*)
        _arg_restart_containers="${_key##-r}"
        ;;
      -h|--help)
        print_help
        exit 0
        ;;
      -h*)
        print_help
        exit 0
        ;;
      *)
        _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
        ;;
    esac
    shift
  done
}

split_list() {
  IFS=',' read -ra CONTAINERS <<< "$1"
  log "Values split! Got '${CONTAINERS[@]}'"
}


###############################################


parse_commandline "$@"

if [ -z "${_arg_restart_containers}" ]; then
  log "--restart-containers is empty. Won't restart containers."
else
  log "Got value of --restart-containers: ${_arg_restart_containers}. Splitting values."
  split_list "${_arg_restart_containers}"
fi

mkdir -p ${WORKDIR}
dump

# while true; do
#  inotifywait -qq -e modify /traefik/acme.json
#  dump
# done