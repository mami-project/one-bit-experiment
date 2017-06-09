TEST_FUN_LOLA_Q_HOST="enb_downstream_sched"
TEST_FUN_LTE_SHAPER_HOST="enb_traffic_shaper"
TEST_FUN_BROWSER="/Applications/FirefoxNightly.app"

docker_up() {
  docker-compose up -d
}

config_lte() {
  docker-compose exec ${TEST_FUN_LTE_SHAPER_HOST} \
    /root/share/config/lte.sh restart
}

config_lola() {
  docker-compose exec ${TEST_FUN_LOLA_Q_HOST} \
    /root/share/config/lola-sched.sh restart
}

start_lola_monitor() {
  docker-compose exec ${TEST_FUN_LOLA_Q_HOST} \
    /root/share/scripts/qmon.sh restart
}

# $1: CSV file to save the results
stop_lola_monitor() {
  docker-compose exec ${TEST_FUN_LOLA_Q_HOST} \
    /root/share/scripts/qmon.sh stop \
      2>/dev/null > "$1"
}

# $1: JSON file (name only)
# $2: directory where to find $1 and dump the broken-down streams
# $3: GNU plot template name
plot_iperf_output() {
  local fname="$1"
  local dname="$2"
  local gnuplot_tmpl="$3"

  local sname="${dname}/$(basename ${fname} .json)-stream_"

  volumes/scripts/iperf3_to_gnuplot.py -f "${dname}/${fname}" | \
    awk -F',' \
      -v sname="${sname}" \
      '!/^#/ { gsub(/[ \t]+/, "", $3); print > sname $3 ".csv" }'

  for csv in ${sname}*
  do
    volumes/scripts/run-gnuplot.sh "${csv}" svg volumes/scripts/${gnuplot_tmpl}.gp
  done
}

# $1: reference iperf results file in JSON format
# $2: original CSV file produced by the lola monitor
plot_lola_stats() {
  local ref="$1"
  local csv="$2"
  local out="$(dirname "${csv}")/$(basename "${csv}" .csv)-trimmed.csv"

  volumes/scripts/align-timeframe.sh "${ref}" "${csv}" > "${out}"
  volumes/scripts/run-gnuplot.sh "${out}" svg volumes/scripts/lola-queue.gp
}

# $1: docker host
# $2: transport port
start_iperf_server() {
  docker-compose exec $1 killall iperf3 || true
  docker-compose exec $1 /root/share/simusers/iperf-server.sh $2
}

# $1: server port
# $2: number of parallel flows
# $3: tos marking
# $4: duration
# $5: log file
start_sut_voip_client() {
  local sport=$1
  local nflows=$2
  local tos_mark=$3
  local duration=$4
  local logfile=$5

  local bw=64000
  local pkt_sz=128

  docker-compose exec sut_sgilan \
    /root/share/simusers/udp-clients.sh \
      sut-mobile \
      ${sport} \
      ${nflows} \
      ${duration} \
      ${tos_mark} \
      "${logfile}" \
      ${bw} \
      ${pkt_sz}
}

# $1: results directory
open_result_dir() {
  open -a "${TEST_FUN_BROWSER}" "$1"
}

# vim: ai ts=2 sw=2 et sts=2 ft=sh
