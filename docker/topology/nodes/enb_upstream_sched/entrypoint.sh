#!/bin/bash

set -eux

readonly DST_SUBNET="$1"
readonly GW="$2"

# Make sure the downstream scheduler knows how to route packets from the
# RAN to the SGi-LAN
ip route add $DST_SUBNET via $GW

readonly NODE_NAME="$3"

# prompt
echo export PS1="\"[${NODE_NAME}] \\W # \"" > /root/.bashrc

bash
