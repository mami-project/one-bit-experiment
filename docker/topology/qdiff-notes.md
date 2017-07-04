# start capture (both in and out)
```
docker-compose exec -d ${docker} tcpdump -s 96 -i ${in}  "${filter}" -w "${RESULT_DIR}/${docker}-in.pcap" &
docker-compose exec -d ${docker} tcpdump -s 96 -i ${out} "${filter}" -w "${RESULT_DIR}/${docker}-out.pcap" &
```

# stop capture
```
docker-compose exec ${docker} killall -TERM tcpdump
```

```
export in=eth1
export out=eth0
```

# extract only packet number and timestamp
# seems a bit brittle
```
for p in 8080 8082 8084
do
	for f in ${in} ${out}
	do
		tshark -t e -T fields -e ip.id -e _ws.col.Time -r ${f}.pcap "udp.dstport==${p}" > ${f}-${p}.txt
	done
done
```

# join the two captures & create the diff
```
for p in 8080 8082 8084
do
	join -j1 ${out}-${p}.txt ${in}-${p}.txt | awk '{x=$2-$3; printf("%f\n", x);}' > ${p}-delay.dat
done
```

# dropped (unmatched) packets
```
for p in 8080 8082 8084
do
	join -v2 ${out}-${p}.txt ${in}-${p}.txt > ${p}-dropped.dat
done
```

# stats (need R)
```
for p in 8080 8082 8084
do
	echo ">>>> [$p]"
	cat ${p}-delay.dat | R --slave -e 'x <- scan(file="stdin",quiet=FALSE); summary(x); sd(x)'
	echo
done
```

# plot delays
```
$ cat delays.gp
set logscale y
set grid xtics ytics
set xlabel 'packet number'
set ylabel 'delay (sec)'
set xrange [0:6500]
plot \
  '8084-delay.dat' title 'Lo' with lines smooth bezier, \
  '8082-delay.dat' title 'La' with lines smooth bezier, \
  '8080-delay.dat' title 'default' with lines smooth bezier, \

$ gnuplot delays.gp
```
