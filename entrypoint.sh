#!/usr/bin/env bash

function spawn {
    if [[ -z ${PIDS+x} ]]; then PIDS=(); fi
    "$@" &
    PIDS+=($!)
}

function join {
    if [[ ! -z ${PIDS+x} ]]; then
        for pid in "${PIDS[@]}"; do
            wait "${pid}"
        done
    fi
}

function on_kill {
    if [[ ! -z ${PIDS+x} ]]; then
        for pid in "${PIDS[@]}"; do
            kill "${pid}" 2> /dev/null
        done
    fi
    kill "${ENTRYPOINT_PID}" 2> /dev/null
}

export ENTRYPOINT_PID="${BASHPID}"

trap "on_kill" EXIT
trap "on_kill" SIGINT

SS_CONFIG="/etc/shadowsocks/config.json"

cat << EOF > "${SS_CONFIG}"
{
    "server": "${SS_SERVER_ADDR}",
    "server_port": ${SS_SERVER_PORT},
    "password": "${SS_SERVER_PASS}",
    "timeout": ${SS_TIMEOUT},
    "method": "${SS_METHOD}",
EOF

if [[ -n "${SS_OBFS}" ]]; then
    if [[ "${SS_OBFS}" == "http" || "${SS_OBFS}" == "tls" ]]; then
        SS_OBFS_OPTS="obfs=${SS_OBFS}"
        if [[ -n "${SS_OBFS_HOST}" ]]; then
            SS_OBFS_OPTS+=";obfs-host=${SS_OBFS_HOST}"
        fi
        if [[ -n "${SS_OBFS_URI}" ]]; then
            SS_OBFS_OPTS+=";obfs-uri=${SS_OBFS_URI}"
        fi
        if [[ -n "${SS_OBFS_HTTP_METHOD}" ]]; then
            SS_OBFS_OPTS+=";http-method=${SS_OBFS_HTTP_METHOD}"
        fi
        if [[ "${SS_FAST_OPEN}" == "true" ]]; then
            SS_OBFS_OPTS+=";fast-open"
        fi
        if [[ "${SS_MPTCP}" == "true" ]]; then
            SS_OBFS_OPTS+=";mptcp"
        fi
        cat << EOF >> "${SS_CONFIG}"
    "plugin": "obfs-local",
    "plugin_opts": "${SS_OBFS_OPTS}",
EOF
    fi
fi

if [[ -n "${SS_KEY}" ]]; then
    cat << EOF >> "${SS_CONFIG}"
    "key": "${SS_KEY}",
EOF
fi

if [[ -n "${SS_TIMEOUT}" ]]; then
    cat << EOF >> "${SS_CONFIG}"
    "timeout": ${SS_TIMEOUT},
EOF
fi

if [[ -n "${SS_USER}" ]]; then
    cat << EOF >> "${SS_CONFIG}"
    "user": "${SS_USER}",
EOF
fi

if [[ -n "${SS_FAST_OPEN}" ]]; then
    cat << EOF >> "${SS_CONFIG}"
    "fast_open": ${SS_FAST_OPEN},
EOF
fi

if [[ -n "${SS_REUSE_PORT}" ]]; then
    cat << EOF >> "${SS_CONFIG}"
    "reuse_port": ${SS_REUSE_PORT},
EOF
fi

if [[ -n "${SS_NOFILE}" ]]; then
    cat << EOF >> "${SS_CONFIG}"
    "nofile": ${SS_NOFILE},
EOF
fi

if [[ -n "${SS_DSCP}" ]]; then
    cat << EOF >> "${SS_CONFIG}"
    "dscp": ${SS_DSCP},
EOF
fi

if [[ -n "${SS_MODE}" ]]; then
    cat << EOF >> "${SS_CONFIG}"
    "mode": "${SS_MODE}",
EOF
fi

if [[ -n "${SS_MTU}" ]]; then
    cat << EOF >> "${SS_CONFIG}"
    "mtu": ${SS_MTU},
EOF
fi

if [[ -n "${SS_MPTCP}" ]]; then
    cat << EOF >> "${SS_CONFIG}"
    "mptcp": ${SS_MPTCP},
EOF
fi

if [[ -n "${SS_IPV6_FIRST}" ]]; then
    cat << EOF >> "${SS_CONFIG}"
    "ipv6_first": ${SS_IPV6_FIRST},
EOF
fi

if [[ -n "${SS_USE_SYSLOG}" ]]; then
    cat << EOF >> "${SS_CONFIG}"
    "use_syslog": ${SS_USE_SYSLOG},
EOF
fi

if [[ -n "${SS_NO_DELAY}" ]]; then
    cat << EOF >> "${SS_CONFIG}"
    "no_delay": ${SS_NO_DELAY},
EOF
fi

cat << EOF >> "${SS_CONFIG}"
    "local_address": "${SS_LOCAL_ADDR}",
    "local_port": ${SS_LOCAL_PORT}
}
EOF

SS_SERVER_IP=$(getent hosts "${SS_SERVER_ADDR}" | awk '{ print $1 }')

mkfifo /shadowsocks-fifo
spawn ss-redir -c "${SS_CONFIG}" --up shadowsocks-up.sh

if [[ -n "${SOCKS5_PORT}" ]]; then
    mkfifo /socks5-fifo
    SOCKS5_UP=socks5-up.sh spawn socks5
    cat /socks5-fifo > /dev/null
    rm -f /socks5-fifo
fi

cat /shadowsocks-fifo > /dev/null
rm -f /shadowsocks-fifo

iptables -t nat -N SS_TCP
iptables -t nat -A SS_TCP -p tcp -d "${SS_SERVER_IP}" -j RETURN
iptables -t nat -A SS_TCP -p tcp -d 0.0.0.0/8 -j RETURN
iptables -t nat -A SS_TCP -p tcp -d 10.0.0.0/8 -j RETURN
iptables -t nat -A SS_TCP -p tcp -d 127.0.0.0/8 -j RETURN
iptables -t nat -A SS_TCP -p tcp -d 169.254.0.0/16 -j RETURN
iptables -t nat -A SS_TCP -p tcp -d 172.16.0.0/12 -j RETURN
iptables -t nat -A SS_TCP -p tcp -d 192.168.0.0/16 -j RETURN
iptables -t nat -A SS_TCP -p tcp -d 224.0.0.0/4 -j RETURN
iptables -t nat -A SS_TCP -p tcp -d 240.0.0.0/4 -j RETURN
iptables -t nat -A SS_TCP -p tcp -j REDIRECT --to-ports "${SS_LOCAL_PORT}"
iptables -t nat -A OUTPUT -p tcp -j SS_TCP

ip route add local default dev lo table 100
ip rule add fwmark 1 lookup 100

iptables -t mangle -N SS_UDP
iptables -t mangle -A SS_UDP -p udp -d 0.0.0.0/8 -j RETURN
iptables -t mangle -A SS_UDP -p udp -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A SS_UDP -p udp -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A SS_UDP -p udp -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A SS_UDP -p udp -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A SS_UDP -p udp -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A SS_UDP -p udp -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A SS_UDP -p udp -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A SS_UDP -p udp -j DROP
iptables -t mangle -A SS_UDP -p udp -j TPROXY --on-port "${SS_LOCAL_PORT}" --tproxy-mark 0x01/0x01
iptables -t mangle -A PREROUTING -p udp -j SS_UDP

if [[ -n "${SOCKS5_UP}" ]]; then
    "${SOCKS5_UP}" &
fi

if [[ -n "${SS_UP}" ]]; then
    "${SS_UP}" &
fi

if [[ $# -gt 0 ]]; then
    "$@"
fi

if [[ $# -eq 0 || "${DAEMON_MODE}" == true ]]; then
    join
fi
