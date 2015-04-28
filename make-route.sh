#!/bin/bash

#set -o xtrace

IF0='eth10'
IF1='eth11'
IF2='eth12'
IF3='eth13'
IF4='eth14'


TB0='1'
TB1='2'
TB2='3'
TB3='4'
TB4='5'


DUMMY_GW='192.168.0.1'

ifip() {
  ip addr show $1 | awk '/inet / {split($2, a, "/"); print a[1]}'
}

ifgw() {
  case $1 in
    ppp*) ip addr show $1 | awk '/inet / {split($4, a, "/"); print a[1]}';;
    eth*) echo $DUMMY_GW ;;
  esac
}

## -------------- cleaning --------------- 
echo '<<< cleaning..'
## hide errors
exec 3>&2 2> /dev/null

ip route del default scope global

while ip route del 192.168.0.1; do echo -n .; done

ip route flush table $TB0
ip route flush table $TB1
ip route flush table $TB2
ip route flush table $TB3
#ip route flush table $TB4

ip rule del dev $IF0 table $TB0
ip rule del dev $IF1 table $TB1
ip rule del dev $IF2 table $TB2
ip rule del dev $IF3 table $TB3
#ip rule del dev $IF4 table $TB4

ip route del dev $IF0 table $TB0
ip route del dev $IF1 table $TB1
ip route del dev $IF2 table $TB2
ip route del dev $IF3 table $TB3
#ip route del dev $IF4 table $TB4

ip route del default dev $IF0
ip route del default dev $IF1
ip route del default dev $IF2
ip route del default dev $IF3
#ip route del default dev $IF4

while ip rule del from "$(ifip $IF0)"; do echo -n .; done
while ip rule del from "$(ifip $IF1)"; do echo -n .; done
while ip rule del from "$(ifip $IF2)"; do echo -n .; done
while ip rule del from "$(ifip $IF3)"; do echo -n .; done
#while ip rule del from "$(ifip $IF4)"; do echo -n .; done

while ip rule del from all iif $IF0; do echo -n .; done
while ip rule del from all iif $IF1; do echo -n .; done
while ip rule del from all iif $IF2; do echo -n .; done
while ip rule del from all iif $IF3; do echo -n .; done
#while ip rule del from all iif $IF4; do echo -n .; done

ip route flush cache

## unhide errors
exec 2>&3
echo -e "\nok"
## -------------- cleaning done --------------- 


echo '<<< setting routes..'
## for eth0 devices doing it here, not in ppp/bond-routes
#ip rule add dev $IF0 lookup $TB0
#ip rule add dev $IF1 lookup $TB1
#ip rule add dev $IF2 lookup $TB2
#ip rule add dev $IF3 lookup $TB3

byAddress() {
  echo '<<< using inet addr!'
  ip route add $(ifgw $IF0) dev $IF0 src $(ifip $IF0) table $TB0
  ip route add $(ifgw $IF1) dev $IF1 src $(ifip $IF1) table $TB1
  ip route add $(ifgw $IF2) dev $IF2 src $(ifip $IF2) table $TB2
#  ip route add $(ifgw $IF3) dev $IF3 src $(ifip $IF3) table $TB3

  ip route add default via $(ifgw $IF0) table $TB0
  ip route add default via $(ifgw $IF1) table $TB1
  ip route add default via $(ifgw $IF2) table $TB2
#  ip route add default via $(ifgw $IF3) table $TB3

  ip rule add from $(ifip $IF0) table $TB0 priority 10
  ip rule add from $(ifip $IF1) table $TB1 priority 10
  ip rule add from $(ifip $IF2) table $TB2 priority 10
#  ip rule add from $(ifip $IF3) table $TB3 priority 10

  ip route add default scope global \
    nexthop via $(ifgw $IF0) dev $IF0 weight 7 \
    nexthop via $(ifgw $IF1) dev $IF1 weight 8 \
    nexthop via $(ifgw $IF2) dev $IF2 weight 9 
#    nexthop via $(ifgw $IF3) dev $IF3 weight 10
}

byDevice() {
  echo '<<< using dev names!'
  ip rule add from $(ifip $IF0) table $TB0
  ip rule add from $(ifip $IF1) table $TB1
  ip rule add from $(ifip $IF2) table $TB2
#  ip route add dev $IF1 table $TB3
  
#  ip route add default dev $IF1 table $TB1
#  ip route add default dev $IF2 table $TB2
#  ip route add default dev $IF3 table $TB3
    
  ip route add 192.168.0.0/24 dev $IF0 scope link table $TB0 #priority 10
  ip route add default via $DUMMY_GW dev $IF0 table $TB0

  ip route add 192.168.0.0/24 dev $IF1 scope link table $TB1 #priority 10
  ip route add default via $DUMMY_GW dev $IF1 table $TB1

  ip route add 192.168.0.0/24 dev $IF2 scope link table $TB2 #priority 10
  ip route add default via $DUMMY_GW dev $IF2 table $TB2

  ip route add default scope global nexthop via $DUMMY_GW dev $IF0

#  ip rule add dev $IF1 table $TB1 #priority 10
#  ip rule add dev $IF2 table $TB2 #priority 10
#  ip rule add dev $IF3 table $TB3 priority 10

#  ip route add default scope global \
#    nexthop via $(ifgw $IF0) dev $IF0 weight 7 \
#    nexthop via $(ifgw $IF1) dev $IF1 weight 8 \
#    nexthop via $(ifgw $IF2) dev $IF2 weight 9 
#    nexthop via $(ifgw $IF3) dev $IF3 weight 10 
}

## run here
#byAddress
byDevice

echo -e "ok"
echo -e "\n>>> ip route show:"
ip route show
echo -e "\n>>> ip rule list:"
ip rule list
echo -e "\n"

exit 0
