#!/bin/bash
#
# TODO(tho) description

set -e
set -o pipefail

readonly CONF=${CONF:-"/root/share/config/default-sched.conf"}

cleanup() {
  echo Removing root qdisc from ${IFACE}
  tc qdisc del dev ${IFACE} root || true
}

add_sfq() {
  local iface="$1"
  local bandwidth_max="$2"

  local -r default_class_id="10"

  tc qdisc add dev ${iface} root handle 1: hfsc default ${default_class_id}

  # Attach one single class that takes all the available bandwidth
  tc class add dev ${iface} parent 1: classid 1:1 \
    hfsc sc rate ${bandwidth_max} \
         ul rate ${bandwidth_max}

  tc class add dev ${iface} parent 1:1 classid 1:${default_class_id} \
    hfsc sc rate ${bandwidth_max} \
         ul rate ${bandwidth_max}

  tc qdisc add dev ${iface} parent 1:${default_class_id} handle ${default_class_id} \
    sfq quantum 1500 perturb 120
}

start() {
  echo Adding SFQ sched on ${IFACE}
  add_sfq ${IFACE} ${BW}
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
