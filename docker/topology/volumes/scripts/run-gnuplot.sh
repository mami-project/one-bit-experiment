#!/bin/bash

if [ $# != 3 ]
then
  echo "Usage: $0 <data file> <terminal type> <gnuplot file>"
  exit 1
fi

set -eux
set -o pipefail

DATA=$1
TERM=$2
SPEC=$3

BASENAME="$(basename "${DATA}" .csv)"
DIRNAME="$(dirname "${DATA}")"

gnuplot -e "data='${DATA}'" \
	-e "term='${TERM}'" \
	${SPEC} \
	> "${DIRNAME}/${BASENAME}.${TERM}"
