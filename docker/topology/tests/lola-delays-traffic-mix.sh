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

readonly SUT_IPERF_PORT_1=8080
readonly SUT_IPERF_PORT_2=8082
readonly SUT_IPERF_PORT_3=8084
start_iperf_servers sut_mobile ${SUT_IPERF_PORT_1} ${SUT_IPERF_PORT_2} ${SUT_IPERF_PORT_3}

readonly TG_IPERF_PORT_1=8081
readonly TG_IPERF_PORT_2=8083
readonly TG_IPERF_PORT_3=8085
start_iperf_servers tg_mobile ${TG_IPERF_PORT_1} ${TG_IPERF_PORT_2} ${TG_IPERF_PORT_3}

readonly DURATION=120

readonly UDP_LOGFILE_1="iperf-udp-dflt-stats.json"
start_sut_voip_clients \
  ${SUT_IPERF_PORT_1} \
  1 \
  0x00 \
  ${DURATION} \
  "${C_RESDIR}/${UDP_LOGFILE_1}"

readonly UDP_LOGFILE_2="iperf-udp-la-stats.json"
start_sut_voip_clients \
  ${SUT_IPERF_PORT_2} \
  1 \
  ${TEST_FUN_LA_MARK} \
  ${DURATION} \
  "${C_RESDIR}/${UDP_LOGFILE_2}"

readonly UDP_LOGFILE_3="iperf-udp-lo-stats.json"
start_sut_voip_clients \
  ${SUT_IPERF_PORT_3} \
  1 \
  ${TEST_FUN_LO_MARK} \
  ${DURATION} \
  "${C_RESDIR}/${UDP_LOGFILE_3}"


readonly TCP_LOGFILE_1="iperf-tcp-dflt-stats.json"
start_tg_tcp_clients \
  ${TG_IPERF_PORT_1} \
  1 \
  0x00 \
  ${DURATION} \
  "${C_RESDIR}/${TCP_LOGFILE_1}"

# greedy flows only
readonly TCP_LOGFILE_2="iperf-tcp-lo-stats.json"
start_tg_tcp_clients \
  ${TG_IPERF_PORT_2} \
  1 \
  ${TEST_FUN_LO_MARK} \
  ${DURATION} \
  "${C_RESDIR}/${TCP_LOGFILE_2}"

# La background traffic, real-time flows only (no greedy)
readonly UDP_LOGFILE_4="iperf-udp-videocall-la-stats.json"
start_tg_video_clients \
  ${TG_IPERF_PORT_3} \
  30 \
  ${TEST_FUN_LA_MARK} \
  ${DURATION} \
  "${C_RESDIR}/${UDP_LOGFILE_4}"

wait_background_runners

readonly LOLA_CSV="${H_RESDIR}/qmon.csv"
stop_lola_monitor "${LOLA_CSV}"
plot_lola_stats "${H_RESDIR}/${UDP_LOGFILE_1}" "${LOLA_CSV}"
plot_iperf_output "${TCP_LOGFILE_1}" "${H_RESDIR}" tcp
plot_iperf_output "${TCP_LOGFILE_2}" "${H_RESDIR}" tcp
plot_iperf_output "${UDP_LOGFILE_1}" "${H_RESDIR}" udp
plot_iperf_output "${UDP_LOGFILE_2}" "${H_RESDIR}" udp
plot_iperf_output "${UDP_LOGFILE_3}" "${H_RESDIR}" udp
plot_iperf_output "${UDP_LOGFILE_4}" "${H_RESDIR}" tcp

open_result_dir ${H_RESDIR}

# vim: ai ts=2 sw=2 et sts=2 ft=sh
