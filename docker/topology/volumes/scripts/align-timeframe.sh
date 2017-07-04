#!/bin/bash

set -eu
set -o pipefail

PROG="$(basename $0)"

JQ="$(type -p jq)"

check_tools() {
  if [ ! -x "${JQ}" ]
  then
    echo "precondition failed: set JQ"
    exit 1
  fi
}

# $1: ref
get_start() {
  cat "$1" | "${JQ}" '.start.timestamp.timesecs'
}

# $1: ref
get_duration() {
  cat "$1" | "${JQ}" '.start.test_start.duration'
}

# $1: file to snip
# $2: start
# $3: length
snip_and_rebase() {
  awk -v start=$2 -v duration=$3 -F',' \
    '$1 > start && $1 <= start + duration { $1 -= start ; print $0 }' \
    "$1"
}

main() {
  if [ $# != 2 ]
  then
    echo "$(basename $0) <reference> <to be aligned>"
    exit 1
  fi

  check_tools

  local ref=$1
  local toalign=$2

  start=$(get_start "${ref}")
  duration=$(get_duration "${ref}")

  snip_and_rebase "${toalign}" "${start}" "${duration}"
}

main "$@"

# vim: ai ts=2 sw=2 et sts=2 ft=sh
