TEST_FUN_LOLA_Q_HOST="enb_downstream_sched"
TEST_FUN_LTE_SHAPER_HOST="enb_traffic_shaper"
#TEST_FUN_BROWSER="/Applications/FirefoxNightly.app"
TEST_FUN_BROWSER="/usr/bin/firefox"

TEST_FUN_LO_MARK=0x04
TEST_FUN_LA_MARK=0x14

test_fun_msg() {
  echo ">> $@"
}

docker_up() {
  docker-compose up -d
}

config_lte() {
  docker-compose exec ${TEST_FUN_LTE_SHAPER_HOST} \
    /root/share/config/lte.sh restart
}

# Configure LoLa on both upstream and downstream scheduler nodes
config_lola() {
  for node in upstream downstream
  do
    docker-compose exec enb_${node}_sched \
      env CONF=/root/share/config/lola-sched-${node}.conf \
        /root/share/config/lola-sched.sh restart
  done
}

config_pie() {
  for node in upstream downstream
  do
    docker-compose exec enb_${node}_sched \
      env CONF=/root/share/config/pie-sched-${node}.conf \
        /root/share/config/pie-sched.sh restart
  done
}

config_default() {
  for node in upstream downstream
  do
    docker-compose exec enb_${node}_sched \
      env CONF=/root/share/config/default-sched-${node}.conf \
        /root/share/config/default-sched.sh restart
  done
}

# The LoLa monitor only runs on the downstream scheduler
start_lola_monitor() {
  docker-compose exec -T -d ${TEST_FUN_LOLA_Q_HOST} \
    /root/share/scripts/qmon.sh restart
}

# The LoLa monitor only runs on the downstream scheduler
# $1: CSV file to save the results
stop_lola_monitor() {
  docker-compose exec ${TEST_FUN_LOLA_Q_HOST} \
    /root/share/scripts/qmon.sh stop \
      2>/dev/null > "$1"
}

# $1: directory where to put the measurements
# $2-: UDP ports of flows to monitor
start_flow_monitor() {
  local outdir="$1"
  local ports="${@:2}"

  docker-compose exec -T -d ${TEST_FUN_LOLA_Q_HOST} \
    env BASEDIR="${outdir}" /root/share/scripts/flow-qmon.sh start ${ports}
}

stop_flow_monitor() {
  local outdir="$1"
  local ports="${@:2}"

  docker-compose exec -T ${TEST_FUN_LOLA_Q_HOST} \
    env BASEDIR="${outdir}" /root/share/scripts/flow-qmon.sh stop ${ports}
}

# $@: UDP ports of flows to monitor
start_flows_monitor() {
  local ports="$@"
  docker-compose exec ${TEST_FUN_LOLA_Q_HOST} \
    /root/share/scripts/flow-qmon.sh start ${ports}
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

# $1: where to find data and plot stuff
# $2-: pairs of UDP ports and label
plot_flow_queue_delay() {
  local outdir="$1"
  local -a pairs=(${@:2})

  local gpfile="${outdir}/delays.gp"

cat << 'EOF' > "${gpfile}"
set terminal svg
set logscale y
set grid xtics ytics
set xlabel 'packet number'
set ylabel 'delay (sec)'
plot \
EOF

  for ((i = 0; i < ${#pairs[@]}; i += 2))
  do
    local port=${pairs[i]}
    local label=${pairs[i+1]}

    echo "'${port}-delay.dat' title '${label}' with lines smooth bezier, \\" >> "${gpfile}"
  done

  ( cd ${outdir} && ls -l && gnuplot $(basename "${gpfile}") > queue-delays.svg )
}

# $1: docker host
# $2-...: transport ports
start_iperf_servers() {
  local container=$1
  shift

  test_fun_msg "killing all iperf3 instances on node ${container}"

  docker-compose exec "${container}" killall iperf3 || true

  for port in "$@"
  do
    test_fun_msg "starting iperf server on ${container}:${port}"

    docker-compose exec -T "${container}" \
      /root/share/simusers/iperf-server.sh ${port}
  done
}

# $1: docker container
# $2: server (IP address or host name) to send traffic to
# $3: server port
# $4: number of parallel flows
# $5: tos marking
# $6: duration
# $7: log file
# $8: bandwidth
# $9: packet size
start_udp_clients() {
  local container=$1
  local saddr=$2
  local sport=$3
  local nflows=$4
  local tos_mark=$5
  local duration=$6
  local logfile=$7
  local bw=$8
  local pkt_sz=$9

  test_fun_msg "${container}->${saddr}:${sport}, running ${nflows} UDP client(s) for ${duration} seconds (TOS=${tos_mark})"

  local cmd="/root/share/simusers/udp-clients.sh \
      ${saddr}    \
      ${sport}    \
      ${nflows}   \
      ${duration} \
      ${tos_mark} \
      ${logfile}  \
      ${bw}       \
      ${pkt_sz}"

  # -T is to work around https://github.com/docker/compose/pull/4737
  docker-compose exec -T ${container} bash -c "${cmd}" &
}

# $1: server port
# $2: number of parallel flows
# $3: tos marking
# $4: duration
# $5: log file
start_sut_voip_clients() {
  local bw=64000
  local pkt_sz=128

  start_udp_clients sut_sgilan sut-mobile $@ ${bw} ${pkt_sz}
}

start_tg_video_clients() {
  local bw=1000000
  local pkt_sz=1000

  start_udp_clients tg_sgilan tg-mobile $@ ${bw} ${pkt_sz}
}

# $1: server port
# $2: number of parallel flows
# $3: tos marking
# $4: duration
# $5: log file
start_sut_skype_hd_video_clients() {
  local bw=1500000
  local pkt_sz=1000

  start_udp_clients sut_sgilan sut-mobile $@ ${bw} ${pkt_sz}
}

# $1: docker container
# $2: server (IP address or host name) to send traffic to
# $3: server port
# $4: number of parallel flows
# $5: tos marking
# $6: duration
# $7: log file
start_tcp_clients() {
  local container=$1
  local saddr=$2
  local sport=$3
  local nflows=$4
  local tos_mark=$5
  local duration=$6
  local logfile=$7

  test_fun_msg "${container}->${saddr}:${sport}, running ${nflows} TCP client(s) for ${duration} seconds (TOS=${tos_mark})"

  local cmd="/root/share/simusers/tcp-clients.sh \
      ${saddr}    \
      ${sport}    \
      ${nflows}   \
      ${duration} \
      ${tos_mark} \
      ${logfile}"

  # -T is to work around https://github.com/docker/compose/pull/4737
  docker-compose exec -T ${container} bash -c "${cmd}" &
}

# TCP tg-sgilan -> tg-mobile
start_tg_tcp_clients() {
  start_tcp_clients tg_sgilan tg-mobile $@
}

# TCP sut-sgilan -> sut-mobile
start_sut_tcp_clients() {
  start_tcp_clients sut_sgilan sut-mobile $@
}

wait_background_runners() {
  test_fun_msg "waiting for background docker commands to complete..."
  wait
}

# $1: results directory
open_result_dir() {
#  open -a "${TEST_FUN_BROWSER}" "$1"
  "${TEST_FUN_BROWSER}" "file:///$(pwd)/$1"
}

# vim: ai ts=2 sw=2 et sts=2 ft=sh
