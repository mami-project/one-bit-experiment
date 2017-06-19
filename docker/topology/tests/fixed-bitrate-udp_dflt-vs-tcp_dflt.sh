#!/bin/bash
#
# This script MUST be run from the topology directory

set -eu
set -o pipefail

source "$(dirname "$0")/test-fun.sh"

RESDIR="results/$(basename $0 .sh)/$(date +%s)"
H_RESDIR="volumes/${RESDIR}"
C_RESDIR="/root/share/${RESDIR}"
mkdir -p "${H_RESDIR}"

docker_up
config_lte
config_lola
start_lola_monitor

readonly SUT_IPERF_PORT=8080
start_iperf_server sut_mobile ${SUT_IPERF_PORT}

readonly TG_IPERF_PORT=8081
start_iperf_server tg_mobile ${TG_IPERF_PORT}

readonly DURATION=60

readonly UDP_LOGFILE="iperf-udp-stats.json"
start_sut_voip_clients \
  ${SUT_IPERF_PORT} \
  1 \
  0x00 \
  ${DURATION} \
  "${C_RESDIR}/${UDP_LOGFILE}"

readonly TCP_LOGFILE="iperf-tcp-stats.json"
start_tg_tcp_clients \
  ${TG_IPERF_PORT} \
  1 \
  0x00 \
  ${DURATION} \
  "${C_RESDIR}/${TCP_LOGFILE}"

wait_background_runners

readonly LOLA_CSV="${H_RESDIR}/qmon.csv"
stop_lola_monitor "${LOLA_CSV}"
plot_lola_stats "${H_RESDIR}/${UDP_LOGFILE}" "${LOLA_CSV}"
plot_iperf_output "${TCP_LOGFILE}" "${H_RESDIR}" tcp
plot_iperf_output "${UDP_LOGFILE}" "${H_RESDIR}" udp

open_result_dir ${H_RESDIR}

# vim: ai ts=2 sw=2 et sts=2 ft=sh
