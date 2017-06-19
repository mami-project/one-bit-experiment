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

readonly SUT_IPERF_PORT_2=8082
#readonly SUT_IPERF_PORT_3=8084
#start_iperf_servers sut_mobile ${SUT_IPERF_PORT_2} ${SUT_IPERF_PORT_3}
start_iperf_servers sut_mobile ${SUT_IPERF_PORT_2}

readonly DURATION=60

readonly UDP_LOGFILE_2="iperf-udp-la-stats.json"
start_sut_voip_clients \
  ${SUT_IPERF_PORT_2} \
  1 \
  ${TEST_FUN_LA_MARK} \
  ${DURATION} \
  "${C_RESDIR}/${UDP_LOGFILE_2}"

#readonly UDP_LOGFILE_3="iperf-udp-lo-stats.json"
#start_sut_voip_clients \
#  ${SUT_IPERF_PORT_3} \
#  1 \
#  ${TEST_FUN_LO_MARK} \
#  ${DURATION} \
#  "${C_RESDIR}/${UDP_LOGFILE_3}"
#
wait_background_runners

readonly LOLA_CSV="${H_RESDIR}/qmon.csv"
stop_lola_monitor "${LOLA_CSV}"
plot_lola_stats "${H_RESDIR}/${UDP_LOGFILE_2}" "${LOLA_CSV}"
plot_iperf_output "${UDP_LOGFILE_2}" "${H_RESDIR}" udp
#plot_iperf_output "${UDP_LOGFILE_3}" "${H_RESDIR}" udp

open_result_dir ${H_RESDIR}

# vim: ai ts=2 sw=2 et sts=2 ft=sh
