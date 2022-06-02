#!/bin/bash -x

for i in {0..${routes_count}}; do
    # wait for interface
    while ! ip link show dev eth$i; do
      sleep 1
    done

    sysctl -q -w net.ipv4.conf.eth$i.rp_filter=0

    # enable IP forwarding and NAT
    sysctl -q -w net.ipv4.conf.eth$i.send_redirects=0
done

sysctl -q -w net.ipv4.conf.all.rp_filter=0
sysctl -q -w net.ipv4.conf.default.rp_filter=0
sysctl -q -w net.ipv4.ip_forward=1

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# wait for network connection
curl --retry 10 http://www.example.com

# reestablish connections
systemctl restart amazon-ssm-agent.service
