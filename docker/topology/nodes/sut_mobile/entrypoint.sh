#!/bin/bash

set -eux

readonly GW="$1"
readonly DST_SUBNET_1="$2"
readonly DST_SUBNET_2="$3"

# Add routes to core and SGi-LAN via eNB
ip route add ${DST_SUBNET_1} via ${GW}
ip route add ${DST_SUBNET_2} via ${GW}

readonly NODE_NAME="$4"

# prompt
echo export PS1="\"[${NODE_NAME}] \\W # \"" > /root/.bashrc

bash
