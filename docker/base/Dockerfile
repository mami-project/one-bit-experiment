# Linux v 4.4.59
FROM alpine:3.5

RUN apk add --no-cache \
      bash \
      bc \
      bridge \
      coreutils \
      drill \
      iperf3 \
      iproute2 \
      iproute2-doc \
      iputils \
      man \
      tcpdump \
      tshark \
      util-linux

# Manually bugfix traffic control distributions.  They are actually installed
# but not in the location tc expects to find them.
RUN ln -s /usr/lib/tc /lib/tc
