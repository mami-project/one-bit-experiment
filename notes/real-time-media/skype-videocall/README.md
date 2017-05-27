# Skype characterisation

## Network requirements
Data extracted from [How much bandwidth does Skype need](https://support.skype.com/en/faq/FA1417/how-much-bandwidth-does-skype-need):

| Call type				| Minimum download / upload speed	| Recommended download / upload speed	|
| -------------------------------------	| -------------------------------------	| -------------------------------------	|
| Calling				| 30kbps / 30kbps			| 100kbps / 100kbps			|
| Video calling / Screen sharing	| 128kbps / 128kbps			| 300kbps / 300kbps			|
| Video calling (high-quality)		| 400kbps / 400kbps			| 500kbps / 500kbps			|
| Video calling (HD)			| 1.2Mbps / 1.2Mbps			| 1.5Mbps / 1.5Mbps			|
| Group video (3 people)		| 512kbps / 128kbps			| 2Mbps / 512kbps			|
| Group video (5 people)		| 2Mbps / 128kbps			| 4Mbps / 512kbps			|
| Group video (7+ people)		| 4Mbps / 128kbps			| 8Mbps / 512kbps			|


Also, from [Network performance requirements from your network Edge to Microsoft network Edge](https://support.office.com/en-gb/article/Media-Quality-and-Network-Connectivity-Performance-in-Skype-for-Business-Online-5fe3e01b-34cf-44e0-b897-b0b2a83f0917)

| Metric		| Target	|
| ---------------------	| -------------	|
| latency (one way)	| < 30ms	|
| latency (RTT)		| < 60ms	|
| burst packet loss	| < 1% in 200ms	|
| packet loss		| < 0.1% in 15s	|
| packet jitter		| < 15ms in 15s	|
| packet reorder	| < 0.01%	|

[This](https://technet.microsoft.com/en-us/library/jj688118(v=ocs.15).aspx) might also be relevant to understand video codec selection.

## Skype characterisation
### A video call
The following data have been extracted from a capture of a [video call](capture.pcapng) with pretty good and stable QoE.

The characteristics of the captured flows seem to correspond to the "Video calling (high-quality)" entry in the table above.

The four individual RTP streams (upstream and downstream audio and video) are described below.

#### Upstream audio
(Average) bandwidth is 63.901 kbps; packets are distributed as follows:
```
==================================================================================================================================
                   Count         Average       Min val       Max val       Rate (ms)     Percent       Burst rate    Burst start  
----------------------------------------------------------------------------------------------------------------------------------
Packet Lengths     1892          159.71        116           248           0.0500        100%          0.0700        32.108       
 80-159            1306          142.58        116           159           0.0345        69.03%        0.0700        32.108       
 160-319           586           197.87        160           248           0.0155        30.97%        0.0600        0.000        
----------------------------------------------------------------------------------------------------------------------------------
```
##### Tshark filter
```
(ip.src==192.168.1.5 && udp.srcport==62858 && ip.dst==79.54.202.67 && udp.dstport==59050 && rtp.ssrc==0xc12783ca)
```

Packets are paced nearly exactly every 20ms as per [SILK speech frame size](https://tools.ietf.org/html/draft-vos-silk-02#section-2.1.1.2).  Given an average size of about 160 bytes, and removing IP, UDP and RTP encapsulation, what's left is about 100 bytes of SILK payload.  This makes about 40kbps bandwidth which corresponds to SWB at 24 kHz sampling rate [SILK sampling rates](https://tools.ietf.org/html/draft-vos-silk-02#section-2.1.1.1).

##### Simulation using iperf3
```
$ AUDIO_BW=63901
$ AUDIO_PACKET_SIZE=126  # 159.71 - (UDP, IP, data link encap)

$ iperf3 --udp \
         --client ${SERVER_IP_ADDR} \
         --port ${SERVER_UDP_PORT} \
         --bandwidth ${AUDIO_BW} \
         --length ${AUDIO_PACKET_SIZE} \
         --time ${CALL_DURATION} \
         ...
```

### Upstream video
(Average) bandwidth is 621.709 kbps; packets are distributed as follows:
```
==================================================================================================================================
                   Count         Average       Min val       Max val       Rate (ms)     Percent       Burst rate    Burst start  
----------------------------------------------------------------------------------------------------------------------------------
Packet Lengths     4243          691.85        81            1245          0.1123        100%          0.2000        14.097       
 80-159            2             87.50         81            94            0.0001        0.05%         0.0200        36.208       
 160-319           82            269.78        172           319           0.0022        1.93%         0.0200        0.000        
 320-639           1825          483.05        320           639           0.0483        43.01%        0.1400        20.134       
 640-1279          2334          870.46        641           1245          0.0618        55.01%        0.1700        30.748       
----------------------------------------------------------------------------------------------------------------------------------
```
##### Tshark filter
```
(ip.src==192.168.1.5 && udp.srcport==62858 && ip.dst==79.54.202.67 && udp.dstport==59050 && rtp.ssrc==0xc12783cb)
```

H.264 is used as codec (https://en.wikipedia.org/wiki/Skype#Video_codecs).

##### Simulation using iperf3
```
$ VIDEO_BW=621709
$ VIDEO_PACKET_SIZE=657  # 691.85 - (UDP, IP, data link encap)

$ iperf3 --udp \
         --client ${SERVER_IP_ADDR} \
         --port ${SERVER_UDP_PORT} \
         --bandwidth ${VIDEO_BW} \
         --length ${VIDEO_PACKET_SIZE} \
         --time ${CALL_DURATION} \
         ...
```

### Downstream audio
(Average) bandwidth is 59.029 kbps; packets are distributed as follows:
```
==================================================================================================================================
                   Count         Average       Min val       Max val       Rate (ms)     Percent       Burst rate    Burst start
----------------------------------------------------------------------------------------------------------------------------------
Packet Lengths     1892          147.48        114           193           0.0500        100%          0.2000        21.746
 80-159            1236          136.31        114           159           0.0327        65.33%        0.1600        21.746
 160-319           656           168.52        160           193           0.0173        34.67%        0.0600        5.838
----------------------------------------------------------------------------------------------------------------------------------
```
##### Tshark filter
```
(ip.src==192.168.1.5 && udp.srcport==62858 && ip.dst==79.54.202.67 && udp.dstport==59050 && rtp.ssrc==0xc12783ca)
```

##### Simulation using iperf3
```
$ AUDIO_BW=59029
$ AUDIO_PACKET_SIZE=123  # 147.48 - (UDP, IP, data link encap)
[...]
```

### Downstream video
(Average) bandwidth is 810541.432927944 kbps; packets are distributed as follows:
```
==================================================================================================================================
                   Count         Average       Min val       Max val       Rate (ms)     Percent       Burst rate    Burst start
----------------------------------------------------------------------------------------------------------------------------------
Packet Lengths     4016          954.05        582           1245          0.1062        100%          0.4600        21.746
 320-639           32            615.12        582           639           0.0008        0.80%         0.1100        21.746
 640-1279          3984          956.77        652           1245          0.1054        99.20%        0.3500        21.746
----------------------------------------------------------------------------------------------------------------------------------
```
##### Tshark filter
```
(ip.src==79.54.202.67 && udp.srcport==59050 && ip.dst==192.168.1.5 && udp.dstport==62858 && rtp.ssrc==0xe76a8a66)
```

##### Simulation using iperf3
```
$ VIDEO_BW=810541
$ VIDEO_PACKET_SIZE=930  # 954.05 - (UDP, IP, data link encap)
[...]
```

## An audio call
Baset et al. in [An Analysis of the Skype Peer-to-Peer Internet Telephony Protocol](http://www1.cs.columbia.edu/~salman/publications/skype1_4.pdf) report packet size for a voice call is in range [40, 120] bytes.  The paper is pretty old (2006) but the figures have not moved dramatically since.

An audio call is like a video call, except there is no video, thus it's just a couple of RTP streams.  The figures are very similar to those derived from the analysis above.

# Misc Notes
QoE upper bounds:
 - packet loss < 5% 
 - packet reordering < 10^(-5)
 - RTT in [150, 200] ms range.  ITU G.10[7-9] recommends 200ms maximum [Mouth-to-ear delay](https://en.wikipedia.org/wiki/Latency_(audio)#Telephone_calls).
 - jitter as small as possible.  [note to self: a (stable) value of 20 -- taken from the "Call Technical Info" menu -- provided a good overall quality]
 - UE considerations: playout is CPU bound, therefore high CPU load imposed by concurrent applications impacts the quality of the renderer
