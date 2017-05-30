#!/bin/bash

set -eux
set -o pipefail

TARGET_BANDWIDTH=$1
LENGTH=$2

BACKGROUND_TRAFFIC_TCP_PORT=9090

iperf3 --client tg-mobile \
       --port ${BACKGROUND_TRAFFIC_TCP_PORT} \
       --time ${LENGTH} \
       --bandwidth ${TARGET_BANDWIDTH} \
       --zerocopy
