#!/bin/bash

set -eu

if [ $# != 9 ]
then
  echo "$(basename $0) <server> <port> <#parallel flows> <duration (sec)> <tos mark> <log dir> <experiment id> <bandwidth> <packet size>"
  echo
  echo "(E.g., to simulate a VoIP call use bandwidth=64000 and packet_size=128)"
  exit 1
fi

SRV=$1
PORT=$2
NFLOWS=$3
DURATION=$4
TOS=$5
LOGDIR=$6
EXP_ID=$7
BW=$8
PACKET_SIZE=$9

LOGFILE="${LOGDIR}/exp_${EXP_ID}_${SRV}:${PORT}_${NFLOWS}:udp_tos:${TOS}_bw:${BW}_packetlen:${PACKET_SIZE}b--$(uuidgen)"

iperf3 --client ${SRV} \
       --port ${PORT} \
       --udp \
       --bandwidth ${BW} \
       --length ${PACKET_SIZE} \
       --time ${DURATION} \
       --parallel ${NFLOWS} \
       --tos ${TOS} \
       --json \
       --get-server-output \
       --logfile "${LOGFILE}"

# vim: ai ts=2 sw=2 et sts=2 ft=sh
