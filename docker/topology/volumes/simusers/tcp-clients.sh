#!/bin/bash

set -eux

if [ $# != 6 ]
then
  echo "$(basename $0) <server> <port> <#parallel flows> <duration (sec)> <tos mark> <log file>"
  exit 1
fi

SRV=$1
PORT=$2
NFLOWS=$3
DURATION=$4
TOS=$5
LOGFILE=$6

POLL_INTERVAL=0.1

iperf3 --client ${SRV} \
       --port ${PORT} \
       --time ${DURATION} \
       --parallel ${NFLOWS} \
       --interval ${POLL_INTERVAL} \
       --tos ${TOS} \
       --json \
       --get-server-output \
       --logfile "${LOGFILE}"

# vim: ai ts=2 sw=2 et sts=2 ft=sh
