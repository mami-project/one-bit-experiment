#!/bin/bash

set -eux

readonly DST_SUBNET_1="$1"
readonly GW_1="$2"
readonly DST_SUBNET_2="$3"
readonly GW_2="$4"

# Make sure the traffic shaper knows how to route packets from the
# SGi-LAN to the RAN and viceversa
ip route add $DST_SUBNET_1 via $GW_1
ip route add $DST_SUBNET_2 via $GW_2

readonly NODE_NAME="$5"

# prompt
echo export PS1="\"[${NODE_NAME}] \\W # \"" > /root/.bashrc

bash
