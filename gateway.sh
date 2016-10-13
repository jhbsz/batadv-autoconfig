#!/bin/sh
CLIENT_VLAN=72
CLIENT_IP='192.168.100.1'
CLIENT_NETMASK='255.255.255.0'
CLIENT_ETHERNET='eth0.1'
CLIENT_DHCP_START=100
CLIENT_DHCP_END=150

MGMT_VLAN=75
MGMT_IP='192.168.200.1'
MGMT_NETMASK='255.255.255.0'
MGMT_ETHERNET=''
MGMT_DHCP_START=100
MGMT_DHCP_END=150


MESH_IFNAME="wlan1s"
MESH_ID="bfw"

AP_IFNAME="wlan1ap"
AP_SSID="users"


PRENAME='tmp'
FILES='batman-adv network dhcp wireless firewall'

uciup()
{
  KEY="$1"
  VALUE="$2"

  echo uci set ${PRENAME}$1=$2
  uci set ${PRENAME}$1="$2"
}

initialize()
{
  for i in $FILES
  do
    name=${PRENAME}${i}
    if [ ! -f "/etc/config/${name}" ]; then
        echo "Create /etc/config/${name}"
        touch "/etc/config/${name}"
    fi
  done
}

## Update packages
#opkg update
#opkg install batctl kmod-batman-adv

initialize

## Configurar bat0
uciup batman-adv.mesh bat0
#uciup batman-adv.mesh.bat0.aggregated_ogms
#uciup batman-adv.mesh.bat0.ap_isolation
#uciup batman-adv.mesh.bat0.bonding
#uciup batman-adv.mesh.bat0.fragmentation
#uciup batman-adv.mesh.bat0.gw_bandwidth
#uciup batman-adv.mesh.bat0.gw_mode
#uciup batman-adv.mesh.bat0.gw_sel_class
#uciup batman-adv.mesh.bat0.log_level
#uciup batman-adv.mesh.bat0.orig_interval
#uciup batman-adv.mesh.bat0.vis_mode
#uciup batman-adv.mesh.bat0.bridge_loop_avoidance
#uciup batman-adv.mesh.bat0.distributed_arp_table
#uciup batman-adv.mesh.bat0.multicast_mode
#uciup batman-adv.mesh.bat0.network_coding
#uciup batman-adv.mesh.bat0.hop_penalty
#uciup batman-adv.mesh.bat0.isolation_mark

# Bat0 device.
uciup network.batmesh interface
uciup network.batmesh.mtu '1532'
uciup network.batmesh.proto 'batadv'
uciup network.batmesh.mesh 'bat0'

# VLAN for clients
uciup network.vlanc device
uciup network.vlanc.type '8021ad'
uciup network.vlanc.name 'vlanc'
uciup network.vlanc.vid $CLIENT_VLAN
uciup network.vlanc.proto 'none'
uciup network.vlanc.ifname '@batmesh'

# Network for clients
uciup network.clients interface
uciup network.clients.type 'bridge'
uciup network.clients.proto 'static'
uciup network.clients.ipaddr $CLIENT_IP
uciup network.clients.netmask $CLIENT_NETMASK
uciup network.clients.ip6assign '60'
uciup network.clients.ifname "vlanc ${CLIENT_ETHERNET}"

# VLAN for clients
uciup network.vlanc device
uciup network.vlanc.type '8021ad'
uciup network.vlanc.name 'vlanc'
uciup network.vlanc.vid $MGMT_VLAN
uciup network.vlanc.proto 'none'
uciup network.vlanc.ifname '@batmesh'

# Network for clients
uciup network.mgmt interface
uciup network.mgmt.type 'bridge'
uciup network.mgmt.proto 'static'
uciup network.mgmt.ipaddr $MGMT_IP
uciup network.mgmt.netmask $MGMT_NETMASK
uciup network.mgmt.ip6assign '60'
uciup network.mgmt.ifname "vlanm ${MGMT_ETHERNET}"

# Wireless
uciup wireless.radio1 wifi-device
uciup wireless.radio1.type 'mac80211'
uciup wireless.radio1.hwmode '11g'
uciup wireless.radio1.path 'platform/10180000.wmac'
uciup wireless.radio1.htmode 'HT20'
uciup wireless.radio1.txpower '20'
uciup wireless.radio1.channel '1'
uciup wireless.radio1.country 'ES'

# MESH
uciup wireless.@wifi-iface[1] wifi-iface
uciup wireless.@wifi-iface[1].device 'radio1'
uciup wireless.@wifi-iface[1].network 'batmesh'
uciup wireless.@wifi-iface[1].encryption 'none'
uciup wireless.@wifi-iface[1].mesh_id $MESH_ID
uciup wireless.@wifi-iface[1].mode 'mesh'
uciup wireless.@wifi-iface[1].ifname $MESH_IFNAME

# AP
uciup wireless.@wifi-iface[2] wifi-iface
uciup wireless.@wifi-iface[2].device 'radio1'
uciup wireless.@wifi-iface[2].mode 'ap'
uciup wireless.@wifi-iface[2].encryption 'none'
uciup wireless.@wifi-iface[2].ssid $AP_SSID
uciup wireless.@wifi-iface[2].network 'clients'
uciup wireless.@wifi-iface[2].ifname $AP_IFNAME


# DHCPs
uciup dhcp.clients uciup dhcp
uciup dhcp.clients.start $CLIENT_DHCP_START
uciup dhcp.clients.limit $CLIENT_DHCP_END
uciup dhcp.clients.leasetime '12h'
uciup dhcp.clients.uciup dhcpv6 'server'
uciup dhcp.clients.ra 'server'
uciup dhcp.clients.interface 'clients'
uciup dhcp.clients.ra_management '1'

uciup dhcp.mgmt uciup dhcp
uciup dhcp.mgmt.start $MGMT_DHCP_START
uciup dhcp.mgmt.limit $MGMT_DHCP_END
uciup dhcp.mgmt.leasetime '12h'
uciup dhcp.mgmt.uciup dhcpv6 'server'
uciup dhcp.mgmt.ra 'server'
uciup dhcp.mgmt.ra_management '1'
uciup dhcp.mgmt.interface 'mgmt'

# firewall

uciup firewall.@zone[0].network 'lan clients mgmt'
