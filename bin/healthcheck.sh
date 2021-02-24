#!/usr/bin/env bash
set -eo pipefail

CHECK="$(ps -ef | grep /usr/bin/dump | grep -v grep | wc -l)"
if [[ "${CHECK}" -eq 1 ]]; then
  exit 0
fi

exit 1
