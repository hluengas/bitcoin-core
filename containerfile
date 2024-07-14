FROM registry.fedoraproject.org/fedora:40 AS build

RUN dnf upgrade -y --refresh; \
    dnf install -y autoconf automake boost-devel gcc-c++ git libevent-devel libnatpmp-devel libtool make miniupnpc-devel python3 sqlite-devel systemtap-sdt-devel wget zeromq-devel; \
    dnf clean all;

COPY ./build-release.sh /root/build-release.sh

RUN /root/build-release.sh

CMD /usr/sbin/bitcoind