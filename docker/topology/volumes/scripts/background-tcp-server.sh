#!/bin/bash

set -eux
set -o pipefail

BACKGROUND_TRAFFIC_TCP_PORT=9090

iperf3 --server \
       --port ${BACKGROUND_TRAFFIC_TCP_PORT}
