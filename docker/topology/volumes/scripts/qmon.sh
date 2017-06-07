#!/bin/bash

SERVICE=qmon

readonly CONF="./qmon.conf"
readonly BGQMON="./bgqmon.sh"
readonly PIDFILE="/var/run/qmon.pid"
readonly OUTFILE="/var/run/qmon.out"
readonly CSVFILE="/var/run/qmon.csv"

read_conf() {
  echo "Reading configuration from ${CONF}"
  source "${CONF}"
}

is_running() {
  if test -e "${PIDFILE}"
  then
    local pid="$(cat "${PIDFILE}")"
    if kill -0 ${pid} > /dev/null 2>&1
    then
      return 0
    fi
  fi

  return 1
}

start() {
  if is_running
  then
    echo "${SERVICE} is already running (stop it first)"
    return 1
  fi

  nohup ${BGQMON} ${QMON_IFACE} ${QMON_POLL_INTERVAL} ${OUTFILE} &
  echo $! > "${PIDFILE}"
}

stop() {
  if ! is_running
  then
    echo "${SERVICE} is not running"
    return
  fi

  local pid="$(cat "${PIDFILE}")"

  echo "killing ${SERVICE} (pid=${pid})"

  kill -TERM ${pid} > /dev/null 2>&1

  awk -f ${QMON_PARSE_SCRIPT} ${OUTFILE}
}

status() {
  if ! is_running
  then
    echo "${SERVICE} is not running"
    # check for a dangling output file and notify if needed
    if test -e "${OUTFILE}"
    then
      echo "dangling ${OUTFILE}"
    fi
  else
    echo "${SERVICE} is running"
  fi
}

main() {
  read_conf

  case "$1" in
    start)
      start
      ;;
    stop)
      stop
      ;;
    status)
      status
      ;;
    *)
      echo "Usage: $(basename $0) {start|stop|status}"
      exit 1
      ;;
  esac
}

main "$@"

# vim: ai ts=2 sw=2 et sts=2 ft=sh
