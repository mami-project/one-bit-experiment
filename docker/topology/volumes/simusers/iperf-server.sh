#!/bin/bash

set -eu

if [ $# != 1 ]
then
  echo "Usage: $(basename $0) <port>"
  exit 1
fi

PORT=$1

iperf3 --server \
       --port ${PORT} \
       --one-off

# vim: ai ts=2 sw=2 et sts=2 ft=sh
