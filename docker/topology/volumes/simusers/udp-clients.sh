#!/bin/bash

set -eux

if [ $# != 8 ]
then
  echo "$(basename $0) <server> <port> <#parallel flows> <duration (sec)> <tos mark> <log file> <bandwidth> <packet size>"
  echo
  echo "(E.g., to simulate a VoIP call use bandwidth=64000 and packet_size=128)"
  exit 1
fi

SRV=$1
PORT=$2
NFLOWS=$3
DURATION=$4
TOS=$5
LOGFILE=$6
BW=$7
PACKET_SIZE=$8

POLL_INTERVAL=0.1

iperf3 --client ${SRV} \
       --port ${PORT} \
       --udp \
       --bandwidth ${BW} \
       --length ${PACKET_SIZE} \
       --time ${DURATION} \
       --parallel ${NFLOWS} \
       --interval ${POLL_INTERVAL} \
       --tos ${TOS} \
       --json \
       --get-server-output \
       --logfile "${LOGFILE}"

exit 0

# vim: ai ts=2 sw=2 et sts=2 ft=sh
