set terminal term font "arial,9" size 1024,1024

set xlabel "t (sec)"

set xtics nomirror
set ytics nomirror
set grid xtics ytics
#set xrange [0:60]

set style line 1 lc rgb "#1E90FF" lt 1 lw 1 pt 1 ps 0.5

# 2x2 plots per flow
set multiplot layout 2,2 title "iperf3 UDP flow (sd=$3)"

# Bandwidth
set format y '%.0s%cbps'
set ylabel "bandwidth (bps)"
plot data using 1:5 title "bw" with linespoints ls 1
unset yrange

# Sent packets
unset format
set ylabel "sent packets (every 100ms)"
plot data using 1:6 title "packets" with steps ls 1

# Packet loss (%)
set ylabel "lost packets (percent)"
plot data using 1:8 title "lost packets (%)" with linespoints ls 1

# Jitter
unset format
set ylabel "jitter (ms)"
plot data using 1:9 title "jitter" with linespoints ls 1

unset multiplot
