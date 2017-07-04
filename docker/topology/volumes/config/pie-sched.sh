#!/bin/bash
#
# TODO(tho) description

set -e
set -o pipefail

readonly CONF=${CONF:-"/root/share/config/pie-sched.conf"}

cleanup() {
  echo Removing root qdisc from ${IFACE}
  tc qdisc del dev ${IFACE} root || true
}

add_pie() {
  local iface="$1"
  local bandwidth_max="$2"
  local max_packets="$3"
  local target_delay="$4"
  local recalc_drop_interval="$5"

  local -r default_class_id="10"

  tc qdisc add dev ${iface} root handle 1: hfsc default ${default_class_id}

  # Attach one single class that takes all the available bandwidth
  # PIE will be attached to it
  tc class add dev ${iface} parent 1: classid 1:1 \
    hfsc sc rate ${bandwidth_max} \
         ul rate ${bandwidth_max}

  tc class add dev ${iface} parent 1:1 classid 1:${default_class_id} \
    hfsc sc rate ${bandwidth_max} \
         ul rate ${bandwidth_max}

  # Don't ECN mark (for now)
  tc qdisc add dev ${iface} parent 1:${default_class_id} \
    pie limit ${max_packets} \
        target ${target_delay} \
        tupdate "${recalc_drop_interval}"
}

start() {
  echo Adding PIE sched on ${IFACE}
  add_pie ${IFACE} ${BW} 1000 20ms 30ms
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
