set terminal term font "arial,9"

set xlabel "t (sec)"

set xtics nomirror
set ytics nomirror
set grid xtics ytics

set style line 1 lc rgb "#1E90FF" lt 1 lw 1 pt 1 ps 0.5

# 6x4 plots
set multiplot layout 6,1 title "LoLa queue"

# root qdisc
set ylabel "root cumulative sent bytes"
plot data using 1:2 title "sent bytes" with linespoints ls 1

set ylabel "root cumulative sent packets"
plot data using 1:3 title "sent packets" with linespoints ls 1

set ylabel "root cumulative dropped packets"
plot data using 1:4 title "dropped packets" with linespoints ls 1

set ylabel "root backlog bytes"
plot data using 1:5 title "backlog bytes" with linespoints ls 1

set ylabel "root backlog packets"
plot data using 1:6 title "backlog packets" with linespoints ls 1

set ylabel "root requeues"
plot data using 1:7 title "requeues" with linespoints ls 1

unset multiplot
