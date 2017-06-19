#!/bin/bash
#
# The LoLa scheduler is modelled as a HFSC qdisc with 3 classes:
# - The Lo class/bearer with a filter on DSCP 000001
# - The La class/bearer with a filter on DSCP 000101
# - A default class/bearer which catches all the remaining traffic
#
# There is one LoLa scheduler for each direction (up- and down-stream).

set -e
set -o pipefail

readonly CONF="/root/share/config/lola-sched.conf"

# Unmarked traffic class (no delay budget)
readonly DEFAULT_CLASS_ID="999"
# Class for loss-sensitive flows (delay budget == QCI 8)
readonly LO_CLASS_ID="200"
readonly LO_DSCP_CODE="0x04"
# Class for latency-sensitive flows (delay budget == QCI 7)
readonly LA_CLASS_ID="100"
readonly LA_DSCP_CODE="0x14"

# TODO hfsc params


cleanup() {
  echo Removing root qdisc from ${IFACE}
  tc qdisc del dev ${IFACE} root || true
}

add_root() {
  local iface="$1"
  local default_class_id="$2"
  local bandwidth_max="$3"

  # Add the root HFSC qdisc and assign and make the default class the fallback
  # if the packet has no LoLa marking.
  tc qdisc add dev ${iface} root handle 1: hfsc default ${default_class_id}

  # Also, let the parent class take all the available bandwidth
  tc class add dev ${iface} parent 1: classid 1:1 \
    hfsc sc rate ${bandwidth_max} \
         ul rate ${bandwidth_max}
}

add_dflt_child() {
  local iface="$1"
  local class_id="$2"
  local bandwidth_max="$3"
  local bandwidth_share="$4"
  local max_delay="$5"

  tc class add dev ${iface} parent 1:1 classid 1:${class_id} \
    hfsc ls m1 0 d ${max_delay} m2 ${bandwidth_share} \
         ul rate ${bandwidth_max}
#    hfsc ls rate ${bandwidth_share} \
#         ul rate ${bandwidth_max}

  tc qdisc add dev ${iface} parent 1:${class_id} handle ${class_id} \
    sfq quantum 1500 perturb 120
}

add_lo_child() {
  local iface="$1"
  local class_id="$2"
  local bandwidth_max="$3"
  local bandwidth_share="$4"
  local max_delay="$5"
  local dscp="$6"

  tc class add dev ${iface} parent 1:1 classid 1:${class_id} \
    hfsc sc m1 0 d ${max_delay} m2 ${bandwidth_share} \
         ul rate ${bandwidth_max}
# use link-share instead of ls + rt (NOPE!)
#  tc class add dev ${iface} parent 1:1 classid 1:${class_id} \
#    hfsc sc m1 ${bandwidth_share} d ${max_delay} m2 ${bandwidth_share} \
#         ul rate ${bandwidth_max}

  tc filter add dev ${iface} parent 1: protocol ip prio ${class_id} u32 \
    match ip tos ${dscp} 0xff flowid 1:${class_id}

  tc qdisc add dev ${iface} parent 1:${class_id} handle ${class_id} \
    sfq quantum 1500 perturb 10
}

add_la_child() {
  local iface="$1"
  local class_id="$2"
  local bandwidth_max="$3"
  local bandwidth_share="$4"
  local max_delay="$5"
  local dscp="$6"

  tc class add dev ${iface} parent 1:1 classid 1:${class_id} \
    hfsc sc m1 ${bandwidth_max} d ${max_delay} m2 ${bandwidth_share} \
         ul rate ${bandwidth_max}

  tc filter add dev ${iface} parent 1: protocol ip prio ${class_id} u32 \
    match ip tos ${dscp} 0xff flowid 1:${class_id}

  tc qdisc add dev ${iface} parent 1:${class_id} handle ${class_id} \
    sfq quantum 1500 perturb 10
}

start() {
  echo Adding LoLa sched on ${IFACE}
  add_root ${IFACE} ${DEFAULT_CLASS_ID} ${BW}
  add_la_child ${IFACE} ${LA_CLASS_ID} ${BW} ${BW_SHARE_LA} ${LA_HFSC_DELAY} ${LA_DSCP_CODE}
  add_lo_child ${IFACE} ${LO_CLASS_ID} ${BW} ${BW_SHARE_LO} ${LO_HFSC_DELAY} ${LO_DSCP_CODE}
  add_dflt_child ${IFACE} ${DEFAULT_CLASS_ID} ${BW} ${BW_SHARE} ${DFLT_HFSC_DELAY}
}

stop() {
  cleanup
}

status() {
  for cmd in qdisc class filter
  do
    echo ">> ${IFACE}::${cmd}"
    tc -s ${cmd} show dev ${IFACE}
  done
}

read_conf() {
  ( >&2 echo Reading configuration from "${CONF}" )
  source "${CONF}"
}

main() {
  read_conf

  case "$1" in
    start)
      start
      ;;
    stop)
      stop
      ;;
    restart)
      stop
      start
      ;;
    status)
      status
      ;;
    *)
      echo "Usage: $(basename $0) {start|stop|restart|status}"
      exit 1
      ;;
  esac
}

main "$@"

# vim: ai ts=2 sw=2 et sts=2 ft=sh
