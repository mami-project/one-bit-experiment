set terminal term font "arial,9" size 1024,1024

set xlabel "t (sec)"

set xtics nomirror
set ytics nomirror
set grid xtics ytics

set style line 1 lc rgb "#1E90FF" lt 1 lw 1 pt 1 ps 0.5
set style line 2 lc rgb "#8C2900" lt 1 lw 1 pt 1 ps 0.5
set style line 3 lc rgb "#007D46" lt 1 lw 1 pt 1 ps 0.5
set style line 4 lc rgb "#8055D2" lt 1 lw 1 pt 1 ps 0.5

set multiplot layout 4,3 title "LoLa queues"

set yrange [0:]

############################################
# root qdisc
############################################

set format y '%.01s%cBps'
set ylabel "sent bytes\n(root qdisc)"
x0=NaN
y0=NaN
plot data using (dx=$1-x0,x0=$1,$1-dx/2):(dy=$2-y0,y0=$2,dy/dx) title "sent bytes" with linespoints ls 1
unset format

set ylabel "dropped packets\n(root qdisc)"
x0=NaN
y0=NaN
plot data using (dx=$1-x0,x0=$1,$1-dx/2):(dy=$4-y0,y0=$4,dy/dx) title "dropped packets" with boxes ls 1

set format y '%.01s%cB'
set ylabel "backlog bytes\n(root qdisc)"
plot data using 1:5 title "backlog bytes" with boxes ls 1
unset format

############################################
# Lo qdisc
############################################

set format y '%.01s%cBps'
set ylabel "sent bytes\n(Lo qdisc)"
x0=NaN
y0=NaN
plot data using (dx=$1-x0,x0=$1,$1-dx/2):(dy=$8-y0,y0=$8,dy/dx) title "sent bytes" with linespoints ls 2
unset format

set ylabel "dropped packets\n(Lo qdisc)"
x0=NaN
y0=NaN
plot data using (dx=$1-x0,x0=$1,$1-dx/2):(dy=$10-y0,y0=$10,dy/dx) title "dropped packets" with boxes ls 2

set format y '%.01s%cB'
set ylabel "backlog bytes\n(Lo qdisc)"
plot data using 1:11 title "backlog bytes" with boxes ls 2
unset format

############################################
# La qdisc
############################################

set format y '%.01s%cBps'
set ylabel "sent bytes\n(La qdisc)"
x0=NaN
y0=NaN
plot data using (dx=$1-x0,x0=$1,$1-dx/2):(dy=$14-y0,y0=$14,dy/dx) title "sent bytes" with linespoints ls 3
unset format

set ylabel "dropped packets\n(La qdisc)"
x0=NaN
y0=NaN
plot data using (dx=$1-x0,x0=$1,$1-dx/2):(dy=$16-y0,y0=$16,dy/dx) title "dropped packets" with boxes ls 3

set format y '%.01s%cB'
set ylabel "backlog bytes\n(La qdisc)"
plot data using 1:17 title "backlog bytes" with boxes ls 3
unset format

############################################
# Default qdisc
############################################
set format y '%.01s%cBps'
set ylabel "sent bytes\n(Default qdisc)"
x0=NaN
y0=NaN
plot data using (dx=$1-x0,x0=$1,$1-dx/2):(dy=$20-y0,y0=$20,dy/dx) title "sent bytes" with linespoints ls 4
unset format

set ylabel "dropped packets\n(Default qdisc)"
x0=NaN
y0=NaN
plot data using (dx=$1-x0,x0=$1,$1-dx/2):(dy=$22-y0,y0=$22,dy/dx) title "dropped packets" with boxes ls 4

set format y '%.01s%cB'
set ylabel "backlog bytes\n(Default qdisc)"
plot data using 1:23 title "backlog bytes" with boxes ls 4
unset format

unset multiplot
