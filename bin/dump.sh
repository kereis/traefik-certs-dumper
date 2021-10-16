#!/bin/bash

workdir=/tmp/work
outputdir=/output
re='^[0-9]+$'

###############################################
####             DUMPING LOGIC             ####
###############################################

dump() {
  log "Clearing dumping directory"
  rm -rf ${workdir:?}/*

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

  if [[ -z "${DOMAIN}" ]]; then
    local diff_available=false
    local workdir_subdirs=(${workdir}/*/)
    for subdir in "${workdir_subdirs[@]}"; do
      local i=$(basename "${subdir}" /)
      # Don't extract "private" because it contains Let's Encrypt key
      if [[ "${i}" != "private" ]]; then
        if
          [[ -f ${workdir}/${i}/cert.pem && -f ${workdir}/${i}/key.pem ]]
        then
          if [[ -f ${outputdir}/${i}/cert.pem && -f ${outputdir}/${i}/key.pem ]] &&
            diff -q "${workdir}/$i/cert.pem" "${outputdir}/$i/cert.pem" >/dev/null &&
            diff -q "${workdir}/$i/key.pem" "${outputdir}/$i/key.pem" >/dev/null; then
            log "Certificate and key for '${i}' still up to date, doing nothing"
          else
            log "Certificate or key for '${i}' differ, updating"
            diff_available=true
            local dir=${outputdir}/${i}
            mkdir -p "${dir}" && mv ${workdir}/${i}/*.pem "${dir}"
          fi
        else
          err "Certificates for domain '${i}' don't exist. Omitting..."
        fi
      fi
    done

    if [[ "${diff_available}" = true ]]; then
      combine_pkcs12
      combine_pem
      change_ownership
      restart_containers
      restart_services
    fi
  elif [[ "${#DOMAINS[@]}" -gt 1 ]]; then
    local diff_available=false
    for i in "${DOMAINS[@]}"; do
      if
        [[ -f ${workdir}/${i}/cert.pem && -f ${workdir}/${i}/key.pem ]]
      then
        if [[ -f ${outputdir}/${i}/cert.pem && -f ${outputdir}/${i}/key.pem ]] &&
          diff -q "${workdir}/$i/cert.pem" "${outputdir}/$i/cert.pem" >/dev/null &&
          diff -q "${workdir}/$i/key.pem" "${outputdir}/$i/key.pem" >/dev/null; then
          log "Certificate and key for '${i}' still up to date, doing nothing"
        else
          log "Certificate or key for '${i}' differ, updating"
          diff_available=true
          local dir=${outputdir}/${i}
          mkdir -p "${dir}" && mv ${workdir}/${i}/*.pem "${dir}"
        fi
      else
        err "Certificates for domain '${i}' don't exist. Omitting..."
      fi
    done

    if [[ "${diff_available}" = true ]]; then
      combine_pkcs12
      combine_pem
      change_ownership
      restart_containers
      restart_services
    fi
  else
    if
      [[ -f ${workdir}/${DOMAINS[0]}/cert.pem && -f ${workdir}/${DOMAINS[0]}/key.pem ]]
    then
      if [[ -f ${outputdir}/cert.pem && -f ${outputdir}/key.pem ]] &&
        diff -q "${workdir}/${DOMAINS[0]}/cert.pem" "${outputdir}/cert.pem" >/dev/null &&
        diff -q "${workdir}/${DOMAINS[0]}/key.pem" "${outputdir}/key.pem" >/dev/null; then
        log "Certificate and key for '${DOMAINS[0]}' still up to date, doing nothing"
      else
        log "Certificate or key for '${DOMAINS[0]}' differ, updating"
        mv ${workdir}/${DOMAINS[0]}/*.pem "${outputdir}/"
        combine_pkcs12
        combine_pem
        change_ownership
        restart_containers
        restart_services
      fi
    else
      err "Certificates for domain '${DOMAINS[0]}' don't exist. Omitting..."
    fi
  fi
}

combine_pem() {
  if [[ -n "${COMBINED_PEM}" ]]; then
    if [[ ! "${COMBINED_PEM}" = *\.pem ]]; then
      #Check if combined_pem filename does have .pem at end of filename
      log "COMBINED_PEM=${COMBINED_PEM} does not have .pem at end of filename."
    else
      if [[ "${#DOMAINS[@]}" -gt 1 ]]; then
        for i in "${DOMAINS[@]}"; do
          if [[ -f ${outputdir}/${i}/cert.pem && -f ${outputdir}/${i}/key.pem ]]; then
            log "Combining key and cert for domain ${i} to single pem with name ${i}/${COMBINED_PEM}"
            cat ${outputdir}/"${i}"/cert.pem ${outputdir}/"${i}"/key.pem >${outputdir}/"${i}"/"${COMBINED_PEM}"
          fi
        done
      else
        if [[ -f ${outputdir}/cert.pem && -f ${outputdir}/key.pem ]]; then
          log "Combining key and cert to single pem with name ${COMBINED_PEM}"
          cat ${outputdir}/cert.pem ${outputdir}/key.pem >${outputdir}/"${COMBINED_PEM}"
        fi
      fi
    fi
  fi
}

combine_pkcs12() {
  if [[ ! "${COMBINE_PKCS12}" = yes ]]; then
    return
  fi

  if [[ -z ${PKCS12_PASSWORD+x} && -n ${PKCS12_PASSWORD_FILE+x} ]]; then
    PKCS12_PASSWORD=$(cat $PKCS12_PASSWORD_FILE)
  fi

  if [[ -z "${DOMAIN}" || "${#DOMAINS[@]}" -gt 1 ]]; then
    local outputdir_subdirs=(${outputdir}/*/)
    for subdir in "${outputdir_subdirs[@]}"; do
      local i=$(basename "${subdir}" /)
      if [[ -f ${outputdir}/${i}/cert.pem && -f ${outputdir}/${i}/key.pem ]]; then
        log "Combining key and cert for domain ${i} to pkcs12 file"
        openssl pkcs12 -export -in ${outputdir}/"${i}"/cert.pem -inkey ${outputdir}/"${i}"/key.pem -out ${outputdir}/"${i}"/cert.p12 -password pass:"${PKCS12_PASSWORD}"
      fi
    done
  else
    if [[ -f ${outputdir}/cert.pem && -f ${outputdir}/key.pem ]]; then
      log "Combining key and cert to pkcs12 file"
      openssl pkcs12 -export -in ${outputdir}/cert.pem -inkey ${outputdir}/key.pem -out ${outputdir}/cert.p12 -password pass:"${PKCS12_PASSWORD}"
    fi
  fi
}

change_ownership() {
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
      find ${outputdir}/ -type f \( -name "*.pem" -o -name "*.p12" \) | while read -r f; do
        chown "${OVERRIDE_UID}":"${OVERRIDE_GID}" "$f"
        chmod g+r "$f"
      done
    fi
  fi
}

restart_containers() {
  if [[ ! -z "${CONTAINERS#}" && "${_docker_available}" = true ]]; then
    log "Trying to restart containers"

    for i in "${CONTAINERS[@]}"; do
      log "Looking up container with name ${i}"

      local found_container=$(docker container inspect -f {{.Id}} "${i}" || echo "")
      if [[ ! -z "${found_container}" ]]; then
        log "Found '${found_container}'. Restarting now..."

        docker restart "${found_container}"

        if [[ $? -eq 0 ]]; then
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
  fi
}

restart_services() {
  if [[ ! -z "${SERVICES#}" && "${_docker_available}" = true ]]; then
    log "Trying to restart services"

    for i in "${SERVICES[@]}"; do
      log "Looking up service with name ${i}"

      local found_service=$(docker service inspect -f {{.ID}} "${i}" || echo "")
      if [[ ! -z "${found_service}" ]]; then
        log "Found '${found_service}'. Running force update now..."

        docker service update --force "${found_service}"

        if [[ $? -eq 0 ]]; then
          log "Restarting service '${found_service}' was successful"
        else
          err "
          Something went wrong while restarting '${found_service}'
          Please check health of services and their tasks and consider restarting them manually.
          "
        fi
      else
        err "Service '${i}' could not be found. Omitting service..."
      fi
    done

    log "Service restarting process done."
  fi
}

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}

check_docker_cmd() {
  local __ret=$1

  [[ -x "$(command -v docker)" ]]
  local _result=$?

  if ((_result == 1)); then

    unset __ret
  else
    eval "$__ret=true"
  fi
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
_arg_restart_services=
SERVICES=
CONTAINERS=
DOMAINS=

print_help() {
  printf '%s\n' "traefik-certs-dumper bash script by Humenius <contact@humenius.me>"
  printf 'Usage: %s [-r|--restart-containers <arg>] [--restart-services <arg>] [-h|--help]\n' "$0"
  printf '\t%s\n' "-r, --restart-containers: Restart containers passed as comma-separated container names (no default)"
  printf '\t%s\n' "-r, --restart-services: Restart docker services (force-update) passed as comma-separated service names (no default)"
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
    --restart-services=*)
      _arg_restart_services="${_key##--restart-services=}"
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

_docker_available=
check_docker_cmd _docker_available

if [[ "${_docker_available}" = true ]]; then
  if [[ -z "${_arg_restart_containers}" ]]; then
    log "--restart-containers is empty. Won't attempt to restart containers."
  else
    log "Got value of --restart-containers: ${_arg_restart_containers}. Splitting values."
    IFS=',' read -ra CONTAINERS <<<"$_arg_restart_containers"
    log "Values split! Got '${CONTAINERS[@]}'"
  fi
  if [[ -z "${_arg_restart_services}" ]]; then
    log "--restart-services is empty. Won't attempt to restart services."
  else
    log "Got value of --restart-services: ${_arg_restart_services}. Splitting values."
    IFS=',' read -ra SERVICES <<<"$_arg_restart_services"
    log "Values split! Got '${SERVICES[@]}'"
  fi
else
  log "Docker command is not available. Restart container functionality will not work!"
  log "In case you need it, consider using the Docker version of this image."
  log "(e.g.: humenius/traefik-certs-dumper:latest)"
fi

if [[ -z "${DOMAIN}" ]]; then
  # die "Environment variable DOMAIN mustn't be empty. Exiting..." 1
  log "Environment variable DOMAIN empty. Will dump all certificates possible..."
else
  log "Got value of DOMAIN: ${DOMAIN}. Splitting values."
  IFS=',' read -ra DOMAINS <<<"$DOMAIN"
  log "Values split! Got '${DOMAINS[@]}'"
fi

mkdir -p ${workdir}
dump

while true; do
  inotifywait -qq -e modify /traefik/acme.json
  dump
done
