#!/bin/bash
#
# use tcpdump instead of tshark for the raw capture as it's 10x faster at
# starting up.

set -eu
set -o pipefail

SERVICE="$(basename $0)"

declare -rxA IFACES=(
  [in]=eth1
  [out]=eth0
)

# Enough to get IP & transport headers
readonly SNAPLEN="96"
# Where to put the captures
readonly BASEDIR="/tmp"

cleanse() {
  # XXX Assume only one flow monitor is running at any point in time
  killall tcpdump 2> /dev/null || true
}

make_filter() {
  local filter="udp port $1"
  shift

  for port in "$@"
  do
    filter="${filter} and udp port ${port}"
  done

  echo "${filter}"
}

# $1: capture filter
start_capture() {
  local filter="$1"

  for k in "${!IFACES[@]}"
  do
    local iface=${IFACES[$k]}
    local pcap_file="${BASEDIR}/${iface}.pcap"

    echo "Starting capture on ${k}({$iface})"
    nohup tcpdump \
      -i "${iface}" \
      -w "${pcap_file}" \
      -s "${SNAPLEN}" \
      "${filter}" \
      &
  done
}

# $@: list of UDP destination ports of the flows we are tracking
start() {
  local ports="$@"

  cleanse
  start_capture "$(make_filter ${ports})"
}

grinder() {
  local ports="$@"

  # Place each flow into separate "in" and "out" files
  for port in ${ports}
  do
    for k in "${!IFACES[@]}"
    do
      local iface=${IFACES[$k]}
      local pcap_file="${BASEDIR}/${iface}.pcap"
      local flow_file="${BASEDIR}/${iface}-${port}.txt"

      tshark \
        -t e \
        -T fields \
        -e ip.id \
        -e _ws.col.Time \
        -r "${pcap_file}" \
        "udp.dstport==${port}" \
        > "${flow_file}"
    done

    # Match packets in the in and out directions and compute the queueing
    # delay
    join \
      -j1 \
      "${BASEDIR}/${IFACES[out]}-${port}.txt" \
      "${BASEDIR}/${IFACES[in]}-${port}.txt" \
      | awk '{ delta = ($2 - $3); printf("%f\n", delta); }' \
      > "${BASEDIR}/${port}-delay.dat"

    # While we are at it, compute drops as well (i.e., packets that were seen
    # in the in direction but don't have a match in the outgoing direction
    join \
      -v2 \
      "${BASEDIR}/${IFACES[out]}-${port}.txt" \
      "${BASEDIR}/${IFACES[in]}-${port}.txt" \
      > "${BASEDIR}/${port}-dropped.dat"
  done
}

# $@: list of UDP destination ports of the flows we are tracking
stop() {
  cleanse
  grinder "$@"
}

status() {
  if pgrep -x tcpdump 2>&1 > /dev/null
  then
    echo "At least one capture is currently ongoing"
  else
    echo "No capture is running at the moment"
  fi
}

usage() {
  echo "Usage: ${SERVICE} {start <port [port ...]>|stop <port [port ...]>|status}"
  exit 1
}

main() {
  case "$1" in
    start)
      [ $# -ge 2 ] || usage
      start "${@:2}"
      ;;
    stop)
      [ $# -ge 2 ] || usage
      stop "${@:2}"
      ;;
    status)
      status
      ;;
    *)
      usage
      ;;
  esac
}

main "$@"

# vim: ai ts=2 sw=2 et sts=2 ft=sh
