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
readonly NFLOWS=1
readonly DURATION=30
readonly TOS_MARK=0x14
readonly LOGFILE="iperf-stats.json"
start_sut_voip_client ${SUT_IPERF_PORT} \
  ${NFLOWS} \
  ${TOS_MARK} \
  ${DURATION} \
  "${C_RESDIR}/${LOGFILE}"

readonly LOLA_RAW_CSV="${H_RESDIR}/qmon.csv"
stop_lola_monitor "${LOLA_RAW_CSV}"
plot_lola_stats "${H_RESDIR}/${LOGFILE}" "${LOLA_RAW_CSV}"
plot_iperf_output "${LOGFILE}" "${H_RESDIR}" udp

open_result_dir ${H_RESDIR}

# vim: ai ts=2 sw=2 et sts=2 ft=sh
