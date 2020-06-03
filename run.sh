#!/bin/bash

workdir=/tmp/work
outputdir=/output
re='^[0-9]+$'

###############################################
####             DUMPING LOGIC             ####
###############################################

dump() {
  log "Clearing dumping directory"
  rm -rf ${workdir}/*

  log "Dumping certificates"
  traefik-certs-dumper file \
    --version v2 \
    --crt-name "cert" \
    --crt-ext ".pem" \
    --key-name "key" \
    --key-ext ".pem" \
    --domain-subdir \
    --dest /tmp/work \
    --source /traefik/acme.json >/dev/null

  if [ "${#DOMAINS[@]}" -gt 1 ]; then
    for i in "${DOMAINS[@]}" ; do
      if
        [[ -f ${workdir}/${i}/cert.pem && -f ${workdir}/${i}/key.pem && \
           -f ${outputdir}/${i}/cert.pem && -f ${outputdir}/${i}/key.pem ]]
      then
        if diff -q ${workdir}/$i/cert.pem ${outputdir}/$i/cert.pem >/dev/null && \
           diff -q ${workdir}/$i/key.pem ${outputdir}/$i/key.pem >/dev/null
        then
          log "Certificate and key for '${i}' still up to date, doing nothing"
        else
          log "Certificate or key for '${i}' differ, updating"
          mv ${workdir}/${i}/*.pem ${dir}/
        fi
      else
        err "Certificates for domain '${i}' don't exist. Omitting..."
      fi
    done
  else
    if
      [[ -f ${workdir}/${DOMAIN}/cert.pem && -f ${workdir}/${DOMAIN}/key.pem && \
         -f ${outputdir}/cert.pem && -f ${outputdir}/key.pem ]]
    then
      if diff -q ${workdir}/${DOMAIN}/cert.pem ${outputdir}/cert.pem >/dev/null && \
         diff -q ${workdir}/${DOMAIN}/key.pem ${outputdir}/key.pem >/dev/null
      then
        log "Certificate and key for '${DOMAIN}' still up to date, doing nothing"
      else
        log "Certificate or key for '${DOMAIN}' differ, updating"
        mv ${workdir}/${DOMAIN}/*.pem ${outputdir}/
      fi
    else
      err "Certificates for domain '${i}' don't exist. Omitting..."
    fi
  fi

  if [[ ! -z "${OVERRIDE_UID}" && ! -z "${OVERRIDE_GID}" ]]; then
    if [[ ! "${OVERRIDE_UID}" =~ $re || ! "${OVERRIDE_GID}" =~ $re ]]; then
      #Check on UID
      if [[ ! "${OVERRIDE_UID}" =~ $re ]]; then
          log "OVERRIDE_UID=${OVERRIDE_UID} is not an integer."
      fi
      #Check on GID
      if [[ ! "${OVERRIDE_GID}" =~ $re ]]; then
          log "OVERRIDE_GID=${OVERRIDE_GID} is not an integer."
      fi
      log "Combination ${OVERRIDE_UID}:${OVERRIDE_GID} is invalid. Skipping file ownership change..."
    else
      log "Changing ownership of certificates and keys"
      find ${outputdir}/ -type f -name "*.pem" -print0 | xargs chown "${OVERRIDE_UID}":"${OVERRIDE_GID}"
    fi
  fi

  if [ ! -z "${CONTAINERS#}" ]; then
    log "Trying to restart containers"
    restart_containers
  fi
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
CONTAINERS=
DOMAINS=

print_help() {
  printf '%s\n' "traefik-certs-dumper bash script by Humenius <contact@humenius.me>"
  printf 'Usage: %s [-r|--restart-containers <arg>] [-h|--help]\n' "$0"
  printf '\t%s\n' "-r, --restart-containers: Restart containers passed as comma-separated container names (no default)"
  printf '\t%s\n' "-h, --help: Prints help"
  printf 'Environment variables:\n'
  printf '\t%s\n' "DOMAIN: Domains whose certificates will be extracted"
}

parse_commandline() {
  while test $# -gt 0; do
    _key="$1"
    case "$_key" in
    -r | --restart-containers)
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
    -h | --help)
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

###############################################

parse_commandline "$@"

if [ -z "${_arg_restart_containers}" ]; then
  log "--restart-containers is empty. Won't attempt to restart containers."
else
  log "Got value of --restart-containers: ${_arg_restart_containers}. Splitting values."
  IFS=',' read -ra CONTAINERS <<< "$_arg_restart_containers"
  log "Values split! Got '${CONTAINERS[@]}'"
fi

if [ -z "${DOMAIN}" ]; then
  die "Environment variable DOMAIN mustn't be empty. Exiting..." 1
else
  log "Got value of DOMAIN: ${DOMAIN}. Splitting values."
  IFS=',' read -ra DOMAINS <<< "$DOMAIN"
  log "Values split! Got '${DOMAINS[@]}'"
fi

mkdir -p ${workdir}
dump

while true; do
  inotifywait -qq -e modify /traefik/acme.json
  dump
done
