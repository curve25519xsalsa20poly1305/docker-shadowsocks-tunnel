# Shadowsocks Docker Tunnel

Wraps your program with Shadowsocks (libev+simple_obfs) network tunnel fully contained in Docker. Also exposes SOCKS5 server to host machine. This allows you to have multiple Shadowsocks connections in different containers serving different programs running inside them through global proxy, or on host machine through SOCKS5 proxy.

Supports latest Docker for both Windows, Linux, and MacOS.

### Related Projects

* [openvpn-tunnel](https://hub.docker.com/r/curve25519xsalsa20poly1305/openvpn-tunnel/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-openvpn-tunnel)) - Wraps your program with OpenVPN network tunnel fully contained in Docker.
* [openvpn-socks5](https://hub.docker.com/r/curve25519xsalsa20poly1305/openvpn-socks5/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-openvpn-socks5)) - Convers OpenVPN connection to SOCKS5 server in Docker.
* [openvpn-aria2](https://hub.docker.com/r/curve25519xsalsa20poly1305/openvpn-aria2/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-openvpn-aria2)) - Extends `openvpn-socks5` with `aria2` support.
* [shadowsocks-tunnel](https://hub.docker.com/r/curve25519xsalsa20poly1305/shadowsocks-tunnel/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-shadowsocks-tunnel)) - This project.
* [shadowsocks-aria2](https://hub.docker.com/r/curve25519xsalsa20poly1305/shadowsocks-aria2/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-shadowsocks-aria2)) - Extends `shadowsocks-tunnel` with `aria2` support.
* [shadowsocksr-tunnel](https://hub.docker.com/r/curve25519xsalsa20poly1305/shadowsocksr-tunnel/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-shadowsocksr-tunnel)) - Wraps your program with ShadowsocksR network tunnel fully contained in Docker. Also exposes SOCKS5 server to host machine.
* [shadowsocksr-aria2](https://hub.docker.com/r/curve25519xsalsa20poly1305/shadowsocksr-aria2/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-shadowsocksr-aria2)) - Extends `shadowsocksr-tunnel` with `aria2` support.

## What it does?

1. It starts Shadowsocks client mode `ss-redir` at default port of `1024`.
2. It starts a SOCKS5 server at `$SOCKS5_PORT`, with optional authentication of `$SOCKS5_USER` and `$SOCKS5_PASS`.
3. It setups iptables rules to redirect all internet traffics initiated inside the container through the Shadowsocks connection.
4. It optionally runs the user specified CMD line from `docker run` positional arguments ([see Docker doc](https://docs.docker.com/engine/reference/run/#cmd-default-command-or-options)). The program will use the Shadowsocks connection inside the container.
5. If user has provided CMD line, and `DAEMON_MODE` environment variable is not set to `true`, then after running the CMD line, it will shutdown the Shadowsocks client and SOCKS5 server, then terminate the container.

## How to use?

Shadowsocks connection options are specified through these container environment variables:

* `SS_SERVER_ADDR` (Default: `"0.0.0.0"`) - Remote server address, can either be a domain name or IP address
* `SS_SERVER_PORT` (Default: `"1080"`) - Remote server port
* `SS_SERVER_PASS` (Default: `""`) - Remote server password
* `SS_METHOD` (Default: `"chacha20-ietf-poly1305"`) - Encryption method cipher. Can be: `"aes-128-gcm"`, `"aes-192-gcm"`, `"aes-256-gcm"`, `"rc4-md5"`, `"aes-128-cfb"`, `"aes-192-cfb"`, `"aes-256-cfb"`, `"aes-128-ctr"`, `"aes-192-ctr"`, `"aes-256-ctr"`, `"bf-cfb"`, `"camellia-128-cfb"`, `"camellia-192-cfb"`, `"camellia-256-cfb"`, `"chacha20-ietf-poly1305"`, `"salsa20"`, `"chacha20 and chacha20-ietf"`
* `SS_OBFS` (Default: `"plain"`) - `simple_obfs`'s scheme, can be `"plain"`, `"http"`, and `"tls"`. `"plain"` will disable the obfuscation plugin.
* `SS_OBFS_HOST` (Default: `""`) - `simple_obfs`'s `host` parameter
* `SS_OBFS_URI` (Default: `""`) - `simple_obfs`'s `uri` parameter
* `SS_OBFS_HTTP_METHOD` (Default: `""`) - `simple_obfs`'s `http_method` parameter
* `SS_KEY` (Default: `""`) - Set the key directly. The key should be encoded with URL-safe Base64
* `TIMEOUT` (Default: `"300"`) - Set the socket timeout in seconds
* `SS_USER` (Default: `""`) - Run as a specific user
* `SS_FAST_OPEN` (Default: `"false"`) - Set to `"true"` for TCP fast open
* `SS_REUSE_PORT` (Default: `"false"`) - Enable port reuse
* `SS_NOFILE` (Default: `"1024"`) - Specify max number of open files, 1024 is the minimum possible value
* `SS_DSCP` (Default: `"1024"`) - A JSON object to specify additional TOS/DSCP listening ports
* `SS_MODE` (Default: `"tcp_and_udp"`) - Can be `"tcp_only"`, `"tcp_and_udp"`, and `"udp_only"`
* `SS_MTU` (Default: `""`) - Specify the MTU in integer of your network interface
* `SS_MPTCP` (Default: `"false"`) - Enable Multipath TCP
* `SS_IPV6_FIRST` (Default: `"false"`) - Resovle hostname to IPv6 address first
* `SS_USE_SYSLOG` (Default: `"false"`) - Use Syslog
* `SS_NO_DELAY` (Default: `"false"`) - Enable TCP_NODELAY
* `SS_LOCAL_ADDR` (Default: `"0.0.0.0"`) - `ss-redir` local listening interface
* `SS_LOCAL_PORT` (Default: `"1024"`) - `ss-redir` local listening port, must be different from `SOCKS5_PORT`

SOCKS5 server options are specified through these container environment variables:

* `SOCKS5_PORT` (Default: `"1080"`) - SOCKS5 server listening port
* `SOCKS5_USER` (Default: `""`) - SOCKS5 server authentication username
* `SOCKS5_PASS` (Default: `""`) - SOCKS5 server authentication password

Other container environment variables:

* `DAEMON_MODE` (Default: `"false"`) - force enter daemon mode when CMD line is specified
* `SOCKS5_UP` (Default: `""`) - optional command to be executed when SOCKS5 server becomes stable
* `SS_UP` (Default: `""`) - optional command to be executed when Shadowsocks connection becomes stable

### Simple Example

The following example will run `curl ifconfig.co/json` through Shadowsocks server `1.2.3.4` with other default settings.

```bash
docker run -it --rm --device=/dev/net/tun --cap-add=NET_ADMIN \
    -e SERVER_ADDR="1.2.3.4" \
    curve25519xsalsa20poly1305/shadowsocks-tunnel \
    curl ifconfig.co/json
```

### Daemon Mode

You can leave the Shadowsocks connection running in background, exposing its SOCKS5 server port to host port, and later use `docker exec` to run your program inside the running container without ever closing and reopening your Shadowsocks connection multiple times. Just leave out the CMD line when you start the container with `docker run`, it will automatically enter daemon mode.

```bash
NAME="myss"
PORT="7777"
docker run --name "${NAME}" -dit --rm --device=/dev/net/tun --cap-add=NET_ADMIN \
    -e SERVER_ADDR="1.2.3.4" \
    -p "${PORT}":1080 \
    curve25519xsalsa20poly1305/shadowsocks-tunnel \
    curl ifconfig.co/json
```

Then you run commads using `docker exec`:

```bash
NAME="myss"
docker exec -it "${NAME}" curl ifconfig.co/json
```

Or use the SOCKS5 server available on host machine:

```bash
curl ifconfig.co/json -x socks5h://127.0.0.1:7777
```

To stop the daemon, run this:

```bash
NAME="myss"
docker stop "${NAME}"
```

### Extends Image

This image only includes `curl` and `wget` for most basic HTTP request usage. If the program you want to run is not available in this image, you can easily extend this image to include anything you need.

Here is a very simple example `Dockerfile` that will install [aria2](http://aria2.github.io/) in its derived image.

```Dockerfile
FROM curve25519xsalsa20poly1305/shadowsocks-tunnel
RUN apk add --no-cache aria2
```

Build this image with:

```bash
# Unix & Windows
docker build -t shadowsocks-aria2 .
```

Finally run it with

```bash
docker run -it --rm --device=/dev/net/tun --cap-add=NET_ADMIN \
    -e SERVER_ADDR="1.2.3.4" \
    -v "${PWD}":/downloads:rw \
    -w /downloads \
    shadowsocks-aria2 \
    arai2c http://example.com/index.html
```

It will download the file using `aria2c` to your host's current directory.

## Contributing

Please feel free to contribute to this project. But before you do so, just make
sure you understand the following:

1\. Make sure you have access to the official repository of this project where
the maintainer is actively pushing changes. So that all effective changes can go
into the official release pipeline.

2\. Make sure your editor has [EditorConfig](https://editorconfig.org/) plugin
installed and enabled. It's used to unify code formatting style.

3\. Use [Conventional Commits 1.0.0-beta.2](https://conventionalcommits.org/) to
format Git commit messages.

4\. Use [Gitflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
as Git workflow guideline.

5\. Use [Semantic Versioning 2.0.0](https://semver.org/) to tag release
versions.

## License

Copyright © 2019 curve25519xsalsa20poly1305 &lt;<curve25519xsalsa20poly1305@gmail.com>&gt;

This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See the COPYING file for more details.
