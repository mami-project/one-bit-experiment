#!/bin/bash

SKYPE_CALL_UDP_PORT="6060"
AUDIO_BW="63901"
AUDIO_PACKET_SIZE="126"  # 159.71 - (UDP, IP, data link encap)
CALL_DURATION="20"
TOS="0x14"

iperf3 --client sut-mobile \
       --port ${SKYPE_CALL_UDP_PORT} \
       --udp \
       --bandwidth ${AUDIO_BW} \
       --length ${AUDIO_PACKET_SIZE} \
       --time ${CALL_DURATION} \
       --tos ${TOS} \
       --format k
