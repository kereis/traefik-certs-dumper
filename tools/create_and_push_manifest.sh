#!/bin/bash
set -euo pipefail

if (( "$#" != 2 )); then
    echo "Illegal number of arguments, need 2 arguments: <output of docker/metadata-action> <desired Docker image name>" >&2
    exit 1
fi

readonly __docker_image_name="$2"

NEW_IMAGE_NAMES=()
LOCAL_IMAGE_NAMES=()
while IFS='\n'; read -ra LOCAL_TAGS; do
    for i in "${LOCAL_TAGS[@]}"; do
        __tag=$(cut -d ':' -f3 <<< "$i")
        LOCAL_IMAGE_NAMES+=("$i")
        NEW_IMAGE_NAMES+=("$__docker_image_name:$__tag")
    done
done <<< "$1"

for image_name in "${NEW_IMAGE_NAMES[@]}"; do
    echo "docker buildx imagetools create -t "$image_name" ${LOCAL_IMAGE_NAMES[@]} localhost:5000/traefik-certs-dumper:armhf"
done

exit 0