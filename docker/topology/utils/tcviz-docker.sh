#!/bin/bash

set -eu
set -o pipefail

readonly TCVIZ="${HOME}/bin/tcviz/tcviz.py"
# Hopefully ${HOME}/bin is in PATH
readonly TCVIZ_INSTALL_ONELINE="mkdir -p ${HOME}/bin && git clone https://github.com/ze-phyr-us/tcviz.git ${HOME}/bin/tcviz"

if [ ! -x "${TCVIZ}" ]
then
  echo "${TCVIZ_INSTALL_ONELINE}"
  exit 1
fi

readonly qdisc_file="/tmp/qdisc_file"
readonly class_file="/tmp/class_file"
readonly filter_file="/tmp/filter_file"

readonly outfmt="pdf"


if [ $# != 2 ]; then
  echo "$0 <docker_node> <network_device>"
  exit 1
fi

readonly NODE=$1
readonly DEV=$2

docker exec ${NODE} tc qdisc show dev ${DEV} > ${qdisc_file}
docker exec ${NODE} tc class show dev ${DEV} > ${class_file}
docker exec ${NODE} tc filter show dev ${DEV} > ${filter_file}

${TCVIZ} "${qdisc_file}" "${class_file}" "${filter_file}" \
  | dot -T${outfmt} > "${NODE}-${DEV}".${outfmt}

# vim: ai ts=2 sw=2 et sts=2 ft=sh
