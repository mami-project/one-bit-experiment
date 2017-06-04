#!/bin/bash

set -eu

PROG="$(basename $0)"

main() {
  if [ $# != 3 ]
  then
    echo "Usage: ${PROG} <interface> <poll interval> <output file>"
    exit 1
  fi

  local iface=$1
  local sample_rate=$2
  local output=$3

  while true
  do
    date +%s.%N >> "${output}"
    tc -s qdisc show dev ${iface} >> "${output}"
    sleep ${sample_rate}
  done
}

main "$@"

# vim: ai ts=2 sw=2 et sts=2 ft=sh
