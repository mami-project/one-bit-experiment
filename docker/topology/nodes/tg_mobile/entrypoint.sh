#!/bin/bash

set -eux

readonly GW="$1"
readonly DST_SUBNET="$2"

# Add routes to SGi-LAN via eNB
ip route add ${DST_SUBNET} via ${GW}

readonly NODE_NAME="$3"

# prompt
echo export PS1="\"[${NODE_NAME}] \\W # \"" > /root/.bashrc

bash
