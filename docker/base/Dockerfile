# Linux v 4.4.forty-something (confusingly uname reports 4.9.27)

FROM alpine:3.5

RUN apk add --no-cache \
      bash \
      iputils \
      iproute2-doc \
      tcpdump \
      man \
      iperf3 \
      iproute2 \
      tcpdump \
      drill \
      bc \
      bridge

# Manually bugfix traffic control distributions.  They are actually installed
# but not in the location tc expects to find them.
RUN ln -s /usr/lib/tc /lib/tc
