set terminal term font "arial,9" size 1024,1024

set xlabel "t (sec)"

set xtics nomirror
set ytics nomirror
set grid xtics ytics

set style line 1 lc rgb "#1E90FF" lt 1 lw 1 pt 1 ps 0.5

# 2x2 plots per flow
set multiplot layout 2,2 title "iperf3 TCP flow (sd=$3)"

# Bandwidth
set yrange [0:100000000]
set format y '%.01s%cbps'
set ylabel "bandwidth (Mbps)"
plot data using 1:5 title "bw" with linespoints ls 1
unset yrange

# Retransmissions
unset format
set ylabel "retransmissions"
plot data using 1:6 title "rtns" with boxes ls 1

# Sender congestion window
set format y '%.01s%cB'
set ylabel "sender cwnd"
plot data using 1:7 title "snd cwnd" with linespoints ls 1

# Round-trip time
unset format
set ylabel "RTT (ms)"
plot data using 1:8 title "rtt" with linespoints ls 1

unset multiplot
