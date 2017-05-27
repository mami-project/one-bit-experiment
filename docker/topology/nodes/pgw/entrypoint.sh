#!/bin/bash

set -eux

# Make sure PGW knows how to route packets from the SGi-LAN to the RAN
readonly DST_SUBNET="$1"
readonly GW="$2"
readonly SRC_ADDR="$3"

ip route add $DST_SUBNET via $GW src $SRC_ADDR

readonly NODE_NAME="$4"

# prompt
echo export PS1="\"[${NODE_NAME}] \\W # \"" > /root/.bashrc

bash
