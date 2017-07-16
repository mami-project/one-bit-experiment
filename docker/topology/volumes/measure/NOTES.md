## compute time in queue and fwd/drop pattern
```
rm -f /tmp/dropfwd /tmp/delta
./seqjoin.awk outfile=out dropfwdfile=/tmp/dropfwd deltafile=/tmp/delta in
```

- plot from drop-pattern
```
r
> x <- scan(pipe("cut -f2 -d ' ' /tmp/dropfwd"))
> plot(cumsum(x), type='s', ylim=c(0, length(x)))
```

- do a box'n'wiskers plot of the TIQ
```
x <- scan(pipe("cut -f2 -d ' ' /tmp/delta"))
boxplot(summary(x), xlab="Beacon flows", ylab="Latency (s)")
mtext("which, e.g., Default", side=1, line=1, at=1)
```

- do an ECDF of the TIQ
```
x <- scan(pipe("cut -f2 -d ' ' /tmp/delta"))
plot(ecdf(x), verticals=T, do.points=F, main="Latency ECDF", xlab="Latency (s)", ylab=NA)
```
