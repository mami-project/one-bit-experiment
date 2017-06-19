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
readonly SUT_IPERF_PORT_AUX=8082
start_iperf_servers sut_mobile ${SUT_IPERF_PORT} ${SUT_IPERF_PORT_AUX}

readonly TG_IPERF_PORT=8081
start_iperf_servers tg_mobile ${TG_IPERF_PORT}

readonly DURATION=300

readonly TCP_LOGFILE_1="iperf-tcp-lo-stats.json"
start_sut_tcp_clients \
  ${SUT_IPERF_PORT} \
  1 \
  ${TEST_FUN_LO_MARK} \
  ${DURATION} \
  "${C_RESDIR}/${TCP_LOGFILE_1}"

readonly TCP_LOGFILE_2="iperf-tcp-la-stats.json"
start_tg_tcp_clients \
  ${TG_IPERF_PORT} \
  1 \
  ${TEST_FUN_LA_MARK} \
  ${DURATION} \
  "${C_RESDIR}/${TCP_LOGFILE_2}"

wait_background_runners

readonly LOLA_CSV="${H_RESDIR}/qmon.csv"
stop_lola_monitor "${LOLA_CSV}"
plot_lola_stats "${H_RESDIR}/${TCP_LOGFILE_1}" "${LOLA_CSV}"
plot_iperf_output "${TCP_LOGFILE_1}" "${H_RESDIR}" tcp
plot_iperf_output "${TCP_LOGFILE_2}" "${H_RESDIR}" tcp

open_result_dir ${H_RESDIR}

# vim: ai ts=2 sw=2 et sts=2 ft=sh
