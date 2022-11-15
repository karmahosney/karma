#!/bin/bash

## 05. IP Tables Flush Command

iptables -F

iptables -X

iptables -t nat -F

iptables -t nat -X

iptables -t mangle -F

iptables -t mangle -X

iptables -P INPUT ACCEPT

iptables -P OUTPUT ACCEPT

iptables -P FORWARD ACCEPT


## 06. default policy for each of the chains

iptables --policy INPUT DROP

iptables --policy FORWARD DROP

iptables --policy OUTPUT DROP



## 07. Open LoopBack Interface

iptables --append INPUT --in-interface lo --jump ACCEPT

iptables --append OUTPUT --out-interface lo --jump ACCEPT


## 08. Allow Connections Initiated by the Machine

## Allow Connection Initiated by wireless interface

iptables --append OUTPUT --out-interface wlp2s0 --jump ACCEPT

## Allow Connection Initiated by wire interface

iptables --append OUTPUT --out-interface enp0s31f6 --jump ACCEPT

iptables --append INPUT --match state --state ESTABLISHED,RELATED --jump ACCEPT



## 09. Filter untrusted traffic

iptables -A INPUT --in-interface wlp2s0

iptables -A INPUT --in-interface enp0s31f6



## 10. Block Invalid Packets

## This rule blocks all packets that are not a SYN packet and don’t belong to an established TCP connection.


iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP



## 11. Block New Packets That Are Not SYN

## This blocks all packets that are new (don’t belong to an established connection) and don’t use the SYN flag.

## This rule is similar to the “Block Invalid Packets” one, but we found that it catches some packets that the other one doesn’t.

iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP



## 12. Block Uncommon MSS Values

## The above iptables rule blocks new packets (only SYN packets can be new packets as per the two previous rules)

## that use a TCP MSS value that is not common. This helps to block dumb SYN floods.

iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP



## 13. Block Packets With Bogus TCP Flags

## The below ruleset blocks packets that use bogus TCP flags, ie. TCP flags that legitimate packets wouldn’t use.

iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP

iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP

iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP

iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP

iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP

iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP





## 14. Block Packets From Private Subnets (Spoofing)

## These rules block spoofed packets originating from private (local) subnets.

## On your public network interface you usually don’t want to receive packets from private source IPs.

## These rules assume that your loopback interface uses the 127.0.0.0/8 IP space.

## These five sets of rules alone already block many TCP-based DDoS attacks at very high packet rates.

## With the kernel settings and rules mentioned above, you’ll be able to filter ACK and SYN-ACK attacks at line rate.

iptables -t mangle -A PREROUTING -s 224.0.0.0/3 -j DROP

iptables -t mangle -A PREROUTING -s 169.254.0.0/16 -j DROP

iptables -t mangle -A PREROUTING -s 172.16.0.0/12 -j DROP

iptables -t mangle -A PREROUTING -s 192.0.2.0/24 -j DROP

iptables -t mangle -A PREROUTING -s 192.168.0.0/16 -j DROP

iptables -t mangle -A PREROUTING -s 10.0.0.0/8 -j DROP

iptables -t mangle -A PREROUTING -s 0.0.0.0/8 -j DROP

iptables -t mangle -A PREROUTING -s 240.0.0.0/5 -j DROP

iptables -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP



## 15. Additional Rules

## This drops all ICMP packets. ICMP is only used to ping a host to find out if it’s still alive.

## Because it’s usually not needed and only represents another vulnerability that attackers can exploit,

## we block all ICMP packets to mitigate Ping of Death (ping flood), ICMP flood and ICMP fragmentation flood.


iptables -t mangle -A PREROUTING -p icmp -j DROP



## 16. This iptables rule helps against connection attacks.

## It rejects connections from hosts that have more than 80 established connections.

## If you face any issues you should raise the limit as this could cause troubles with

## legitimate clients that establish a large number of TCP connections.

iptables -A INPUT -p tcp -m connlimit --connlimit-above 80 -j REJECT --reject-with tcp-reset



## 17. Limits the new TCP connections that a client can establish per second.

## This can be useful against connection attacks,

## but not so much against SYN floods because the usually use an endless amount of different spoofed source IPs.

iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT

iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP



## 18. This rule blocks fragmented packets.

## Normally you don’t need those and blocking fragments will mitigate UDP fragmentation flood.

## But most of the time UDP fragmentation floods use a high amount of bandwidth that is likely to exhaust the capacity of your network card,

## which makes this rule optional and probably not the most useful one.

iptables -t mangle -A PREROUTING -f -j DROP



## 19. This limits incoming TCP RST packets to mitigate TCP RST floods. Effectiveness of this rule is questionable.

iptables -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT

iptables -A INPUT -p tcp --tcp-flags RST RST -j DROP


## 20. Mitigating SYN Floods With SYNPROXY

## SYNPROXY is a new target of iptables that has been added in Linux kernel version 3.12 and iptables 1.4.21.

## CentOS 7 backported the feature and it’s available in its 3.10 default kernel.

## The purpose of SYNPROXY is to check whether the host that sent the SYN packet actually establishes a full TCP connection

## or just does nothing after it sent the SYN packet.

## If it does nothing, it discards the packet with minimal performance impact.

## While the iptables rules that we provided above already block most TCP-based attacks,

## the attack type that can still slip through them if sophisticated enough is a SYN flood.

## It’s important to note that the performance of the rules will always be better if we find a certain pattern or signature to block,

## such as packet length (-m length), TOS (-m tos), TTL (-m ttl) or strings and hex values (-m string and -m u32 for the more advanced users).

## But in some rare cases that’s not possible or at least not easy to achieve. So, in these cases, you can make use of SYNPROXY.

## Here are iptables SYNPROXY rules that help mitigate SYN floods that bypass our other rules:

iptables -t raw -A PREROUTING -p tcp -m tcp --syn -j CT --notrack

iptables -A INPUT -p tcp -m tcp -m conntrack --ctstate INVALID,UNTRACKED -j SYNPROXY --sack-perm --timestamp --wscale 7 --mss 1460

iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
