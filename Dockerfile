FROM golang:latest as builder
WORKDIR /go/src/socks5
COPY socks5.go .
RUN go get && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-s' -o ./socks5


FROM alpine:latest

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk upgrade \
    && apk add --no-cache bash curl wget git iptables \
    && apk add --no-cache --virtual .build-deps gettext-dev \
        automake build-base autoconf libtool linux-headers pcre-dev \
        c-ares-dev mbedtls-dev libev-dev udns-dev libsodium-dev zlib-dev \
    && git clone --recurse-submodules -j8 https://github.com/shadowsocks/simple-obfs.git \
    && git clone --recurse-submodules -j8 https://github.com/shadowsocks/shadowsocks-libev.git

RUN cd simple-obfs \
    && ./autogen.sh \
    && ./configure --prefix=/usr --disable-documentation \
    && make install -j8 \
    && cd ..

COPY shadowsocks.patch shadowsocks-libev/

RUN cd shadowsocks-libev \
    && patch -p1 < shadowsocks.patch \
    && ./autogen.sh \
    && ./configure --prefix=/usr --disable-documentation \
    && make install -j8 \
    && cd ..

RUN runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-* \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache --virtual .run-deps $runDeps

COPY socks5-up.sh /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/
COPY shadowsocks-up.sh /usr/local/bin/
COPY --from=builder /go/src/socks5/socks5 /usr/local/bin/

RUN rm -rf simple-obfs shadowsocks-libev-master \
    && apk del .build-deps \
    && chmod +x \
        /usr/local/bin/socks5-up.sh \
        /usr/local/bin/entrypoint.sh \
        /usr/local/bin/shadowsocks-up.sh \
    && mkdir -p /etc/shadowsocks

# Shashowsocks Options
ENV     SS_SERVER_ADDR      "0.0.0.0"
ENV     SS_SERVER_PORT      "1080"
ENV     SS_SERVER_PASS      ""
ENV     SS_METHOD           "chacha20-ietf-poly1305"
ENV     SS_OBFS             "plain"
ENV     SS_OBFS_HOST        ""
ENV     SS_OBFS_URI         ""
ENV     SS_OBFS_HTTP_METHOD ""
ENV     SS_KEY              ""
ENV     SS_TIMEOUT          "300"
ENV     SS_USER             ""
ENV     SS_FAST_OPEN        "false"
ENV     SS_REUSE_PORT       "false"
ENV     SS_NOFILE           "1024"
ENV     SS_DSCP             ""
ENV     SS_MODE             "tcp_and_udp"
ENV     SS_MTU              ""
ENV     SS_MPTCP            "false"
ENV     SS_IPV6_FIRST       "false"
ENV     SS_USE_SYSLOG       "false"
ENV     SS_NO_DELAY         ""
ENV     SS_LOCAL_ADDR       "0.0.0.0"
ENV     SS_LOCAL_PORT       "1024"
ENV     SS_UP  ""

# SOCKS5 Proxy Options
ENV     SOCKS5_PORT      "1080"
ENV     SOCKS5_USER      ""
ENV     SOCKS5_PASS      ""
ENV     DAEMON_MODE      "false"
ENV     SOCKS5_UP        ""

ENTRYPOINT [ "entrypoint.sh" ]
