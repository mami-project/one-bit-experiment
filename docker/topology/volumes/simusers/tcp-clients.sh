#!/bin/bash

set -eu

if [ $# != 7 ]
then
  echo "$(basename $0) <server> <port> <#parallel flows> <duration (sec)> <tos mark> <log dir> <experiment id>"
  exit 1
fi

SRV=$1
PORT=$2
NFLOWS=$3
DURATION=$4
TOS=$5
LOGDIR=$6
EXP_ID=$7

LOGFILE="${LOGDIR}/exp_${EXP_ID}_${SRV}:${PORT}_${NFLOWS}:tcp_tos:${TOS}--$(uuidgen)"

iperf3 --client ${SRV} \
       --port ${PORT} \
       --time ${DURATION} \
       --parallel ${NFLOWS} \
       --tos ${TOS} \
       --json \
       --get-server-output \
       --logfile "${LOGFILE}"

# vim: ai ts=2 sw=2 et sts=2 ft=sh
