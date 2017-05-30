#!/bin/bash
#
# The LoLa scheduler is modelled as a HFSC qdisc with 3 classes:
# - The Lo class/bearer with a filter on DSCP 000001
# - The La class/bearer with a filter on DSCP 000101
# - A default class/bearer which catches all the remaining traffic

set -exu
set -o pipefail

readonly IFACE="eth0"

# Unmarked traffic class (no delay budget)
readonly DEFAULT_CLASS_ID="999"
# Class for loss-sensitive flows (delay budget == QCI 8)
readonly LO_CLASS_ID="200"
readonly LO_DSCP_CODE="0x04"
# Class for latency-sensitive flows (delay budget == QCI 7)
readonly LA_CLASS_ID="100"
readonly LA_DSCP_CODE="0x14"

cleanup() {
  tc qdisc del dev ${IFACE} root || true
}

add_root() {
  local iface="$1"
  local class_id="$2"
  local bandwidth="$3"

  tc qdisc add dev ${iface} root handle 1: hfsc default ${class_id}

  # The parent class takes all the avaialable bandwidth
  tc class add dev ${iface} parent 1: classid 1:1 \
    hfsc sc rate ${bandwidth} \
         ul rate ${bandwidth}
}

add_dflt_child() {
  local iface="$1"
  local class_id="$2"
  local bandwidth="$3"
  local rate="$4"

  tc class add dev ${iface} parent 1:1 classid 1:${class_id} \
    hfsc ls rate ${rate} \
         ul rate ${bandwidth} 

  tc qdisc add dev ${iface} parent 1:${class_id} handle ${class_id} \
    sfq quantum 1500 perturb 10
}

add_lola_child() {
  local iface="$1"
  local class_id="$2"
  local bandwidth="$3"
  local rate="$4"
  local max_delay="$5"
  local dscp="$6"

  tc class add dev ${iface} parent 1:1 classid 1:${class_id} \
    hfsc sc dmax ${max_delay} rate ${rate} \
         ul rate ${bandwidth}

  tc filter add dev ${iface} parent 1: protocol ip prio ${class_id} u32 \
    match ip tos ${dscp} 0xff flowid 1:${class_id}

  tc qdisc add dev ${iface} parent 1:${class_id} handle ${class_id} \
    sfq quantum 1500 perturb 10
}

main() {
  cleanup
  add_root ${IFACE} ${DEFAULT_CLASS_ID} 100mbit
  add_lola_child ${IFACE} ${LA_CLASS_ID} 100mbit 33mbit 100ms ${LA_DSCP_CODE}
  add_lola_child ${IFACE} ${LO_CLASS_ID} 100mbit 33mbit 300ms ${LO_DSCP_CODE}
  add_dflt_child ${IFACE} ${DEFAULT_CLASS_ID} 100mbit 33mbit
}

main

# vim: ai ts=2 sw=2 et sts=2 ft=sh
