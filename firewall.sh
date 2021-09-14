#!/bin/bash


# Quit if not root
if [ $(id -u) -ne 0 ]
then
    echo "Please run with root permissions"
    exit 1
fi


# Reset all tables
iptables -t filter -F
iptables -t filter -X
iptables -t filter -Z

iptables -t nat -F
iptables -t nat -X
iptables -t nat -Z

iptables -t mangle -F
iptables -t mangle -X
iptables -t mangle -Z


# Allow ssh traffic for management
iptables -t filter -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --sport 22 -j ACCEPT


# Default drop policy
iptables -t filter -P INPUT DROP
iptables -t filter -P OUTPUT DROP
iptables -t filter -P FORWARD DROP

# Allow localhost traffic
iptables -t filter -A OUTPUT -o lo -d 127.0.0.1 -j ACCEPT
iptables -t filter -A INPUT -i lo -s 127.0.0.1 -j ACCEPT

# Allow udp, tcp and icmp initiated by host
iptables -t filter -A OUTPUT -p udp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A INPUT -p udp -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -t filter -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A INPUT -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -t filter -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT


# Used by Docker on top of filter FORWARD chain
sudo iptables -t filter -N DOCKER-USER

# Allow udp, tcp and icmp initiaded by Docker containers
iptables -t filter -A DOCKER-USER -s 172.0.0.0/8 ! -d 172.0.0.0/8 -p udp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A DOCKER-USER ! -s 172.0.0.0/8 -d 172.0.0.0/8 -p udp -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -t filter -A DOCKER-USER -s 172.0.0.0/8 ! -d 172.0.0.0/8 -p tcp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A DOCKER-USER ! -s 172.0.0.0/8 -d 172.0.0.0/8 -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -t filter -A DOCKER-USER -s 172.0.0.0/8 ! -d 172.0.0.0/8 -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A DOCKER-USER ! -s 172.0.0.0/8 -d 172.0.0.0/8 -p icmp -m state --state ESTABLISHED -j ACCEPT

# Allow WAN connection initiation on specified ports
if [ -f .env ]
then
    PEER_PORT=$(grep -Po "(?<=^PEER_PORT=)\d+$" .env)
    RPC_PORT=$(grep -Po "(?<=^RPC_PORT=)\d+$" .env)

    if [ -n "${PEER_PORT}" ]
    then
        iptables -t filter -A DOCKER-USER -p tcp -d 172.20.0.0/16 --dport ${PEER_PORT} -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
        iptables -t filter -A DOCKER-USER -p tcp -s 172.20.0.0/16 --sport ${PEER_PORT} -m state --state ESTABLISHED,RELATED -j ACCEPT
    fi

    if [ -n "${RPC_PORT}" ]
    then
        iptables -t filter -A DOCKER-USER -p tcp -d 172.20.0.0/16 --dport ${RPC_PORT} -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
        iptables -t filter -A DOCKER-USER -p tcp -s 172.20.0.0/16 --sport ${RPC_PORT} -m state --state ESTABLISHED,RELATED -j ACCEPT
    fi
fi

# Default drop policy for others
iptables -t filter -A DOCKER-USER -j DROP


# Save rules to configuration file
iptables-save -f /etc/iptables/iptables.rules


# Disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" > /etc/sysctl.d/40-ipv6.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.d/40-ipv6.conf
sysctl -p /etc/sysctl.d/40-ipv6.conf
