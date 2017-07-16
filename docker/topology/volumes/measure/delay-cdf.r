svg("beacon-flows-cdf.svg")
x <- scan("8080-delay.dat")
y <- scan("8082-delay.dat")
z <- scan("8084-delay.dat")

DefaultColour <- rgb(1, 0, 0)
LaColour <- rgb(0, 1, 0)
LoColour <- rgb(0, 0, 1)

plot(ecdf(x), verticals=T, do.points=F, main="Latency CDF", xlab="Latency (s)", ylab=NA, col=DefaultColour)
plot(ecdf(y), verticals=T, do.points=F, add=T, col=LaColour)
plot(ecdf(z), verticals=T, do.points=F, add=T, col=LoColour)

legend("right", c("Default", "La", "Lo"), fill=c(DefaultColour, LaColour, LoColour))

dev.off()
