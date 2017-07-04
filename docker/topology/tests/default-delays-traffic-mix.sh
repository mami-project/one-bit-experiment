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

readonly DURATION=120

readonly SUT_IPERF_PORT_1=8080
readonly TG_IPERF_PORT_1=8081
readonly TG_IPERF_PORT_2=8083
readonly TG_IPERF_PORT_3=8085

readonly UDP_LOGFILE_1="iperf-udp-dflt-stats.json"

readonly TCP_LOGFILE_1="iperf-tcp-dflt-stats.json"
readonly TCP_LOGFILE_2="iperf-tcp-lo-stats.json"
readonly UDP_LOGFILE_4="iperf-udp-videocall-la-stats.json"

readonly LOLA_CSV="${H_RESDIR}/qmon.csv"

docker_up

config_lte
config_default

#start_default_monitor
start_flow_monitor "${C_RESDIR}" ${SUT_IPERF_PORT_1}

start_iperf_servers sut_mobile ${SUT_IPERF_PORT_1}
start_iperf_servers tg_mobile ${TG_IPERF_PORT_1} ${TG_IPERF_PORT_2} ${TG_IPERF_PORT_3}

# beacon
start_sut_voip_clients \
  ${SUT_IPERF_PORT_1} \
  1 \
  0x00 \
  ${DURATION} \
  "${C_RESDIR}/${UDP_LOGFILE_1}"

# 20 greedy
start_tg_tcp_clients \
  ${TG_IPERF_PORT_1} \
  20 \
  0x00 \
  ${DURATION} \
  "${C_RESDIR}/${TCP_LOGFILE_1}"

# +20 greedy
start_tg_tcp_clients \
  ${TG_IPERF_PORT_2} \
  20 \
  0x00 \
  ${DURATION} \
  "${C_RESDIR}/${TCP_LOGFILE_2}"

# +30 non-greedy
start_tg_video_clients \
  ${TG_IPERF_PORT_3} \
  30 \
  0x00 \
  ${DURATION} \
  "${C_RESDIR}/${UDP_LOGFILE_4}"

wait_background_runners

stop_flow_monitor "${C_RESDIR}" ${SUT_IPERF_PORT_1}
#stop_default_monitor "${LOLA_CSV}"

plot_flow_queue_delay "${H_RESDIR}" \
  ${SUT_IPERF_PORT_1} "default"
#plot_default_stats "${H_RESDIR}/${UDP_LOGFILE_1}" "${LOLA_CSV}"

plot_iperf_output "${TCP_LOGFILE_1}" "${H_RESDIR}" tcp
plot_iperf_output "${TCP_LOGFILE_2}" "${H_RESDIR}" tcp
plot_iperf_output "${UDP_LOGFILE_1}" "${H_RESDIR}" udp
plot_iperf_output "${UDP_LOGFILE_4}" "${H_RESDIR}" udp

open_result_dir ${H_RESDIR}

# vim: ai ts=2 sw=2 et sts=2 ft=sh
