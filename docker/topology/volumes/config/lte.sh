#!/bin/bash
#
# To be run on the traffic shaper.
# Sets uplink and downlink bandwidth and latency / loss / reordering
#
# USA (Cat 4)
# - channel: 20MHz
# - antenna: 2x2
# - uplink peak: 50-75.4Mbps
# - uplink median per UE: 5Mbps
# - downlink peak: 101-150Mbps
# - downlink median per UE: 12Mbps
# - one-way delay (median overall, gets slightly smaller at high data rates) [1]
#   - downlink 12ms
#   - uplink: 20ms
# [1] (https://www.itu.int/en/ITU-T/Workshops-and-Seminars/qos/072014/Documents/Presentations/S2P2_Joachim-Pomy.ppt)

set -e
set -o pipefail

readonly CONF="./lte.conf"

cleanup() {
  for k in "${!IFACES[@]}"
  do
    local iface=${IFACES[$k]}
    echo "Removing qdiscs on ${k}({$iface})"
    tc qdisc del dev ${iface} root || true
  done
}

status() {
  for k in "${!IFACES[@]}"
  do
    local iface=${IFACES[${k}]}
    for cmd in qdisc class filter
    do
      echo ">> ${iface}(${k})::${cmd}"
      tc -s ${cmd} show dev ${iface}
    done
  done
}

shape() {
  local iface="$1"
  local bandwidth="$2"
  local latency="$3"

  tc qdisc add dev ${iface} root handle 1:0 htb default 10
  tc class add dev ${iface} parent 1:0 classid 1:10 htb rate ${bandwidth}
  tc qdisc add dev ${iface} parent 1:10 handle 10:0 netem delay ${latency}
}

delayonly() {
  local iface="$1"
  local latency="$2"

  tc qdisc add dev ${iface} root handle 1: netem delay ${latency}

  # Prevent netem from reordering packets if ${latency} has lot of jitter
  tc qdisc add dev ${iface} parent 1:1 pfifo limit 1000
}

shape_uplink() {
  echo "Shaping uplink (${IFACES[downlink]})"
  shape ${IFACES[uplink]} ${UL_BW} ${UL_DELAY}
}

shape_downlink() {
  echo "Shaping downlink (${IFACES[downlink]})"
  shape ${IFACES[downlink]} ${DL_BW} ${DL_DELAY}
}

start() {
  shape_uplink
  shape_downlink
}

stop() {
  cleanup
}

main() {
  echo Reading configuration from "${CONF}"
  source "${CONF}"

  case "$1" in
    start)
      start
      ;;
    stop)
      stop
      ;;
    status)
      status
      ;;
    *)
      echo "Usage: $(basename $0) {start|stop|status}"
      exit 1
      ;;
  esac
}

main "$@"

# vim: ai ts=2 sw=2 et sts=2 ft=sh
