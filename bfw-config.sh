#!/bin/sh

CLIENT_VLAN=72
CLIENT_IP='192.168.100.1'
CLIENT_NETMASK='255.255.255.0'
CLIENT_DHCP_START=100
CLIENT_DHCP_END=150

MGMT_VLAN=75
MGMT_IP='192.168.200.1'
MGMT_NETMASK='255.255.255.0'
MGMT_DHCP_START=100
MGMT_DHCP_END=150

MESH_IFNAME="wlan1s"
MESH_ID="bfw"
MESH_MODE="mesh"
MESH_RADIO="radio1"
MESH_SSID="bfw"

AP_IFNAME="wlan1ap"
AP_SSID="BestFreeWifi"
AP_RADIO="radio1"

SYSTEM_NAME="bfw-"

# definim ports ethernet connectats a la xarxa clients o manager.

GW_ETH_CLIENTS="eth0.1"
GW_ETH_MGMT=""
OTHER_ETH_CLIENTS=""
OTHER_ETH_MGMT=""

HW=$(cat /proc/cpuinfo |grep machine|cut -d : -f 2|xargs|cut -d " " -f 2)

DEVICE_TYPE="client"
BATADV_DEVICE='@batmesh'

PRENAME=''
FILES='batman-adv network dhcp wireless firewall bestfw'

uciup()
{
  KEY="$1"
  VALUE="$2"

  echo uci set ${PRENAME}$1=$2
  uci -q set ${PRENAME}$1="$2"
}

ucicommit()
{
  uci commit
}

ucidelete()
{
  echo uci delete $1
  uci -q delete $1
}

check_packages()
{
  (opkg list-installed|grep -q batctl) || return 1;
  (opkg list-installed|grep -q kmod-batman-adv) || return 1;
  return 0;
}

install_packages()
{
    opkg update
    opkg install batctl kmod-batman-adv
}

set_system_name()
{
    RANDOM_NUMBER=$(date | md5sum | sed -r 's/^(.{6}).*$/\1/;')
    uciup system.@system[0].hostname "${SYSTEM_NAME}${RANDOM_NUMBER}"
}

check_type()
{
    LOCAL_ROUTER_TYPE=$(uci -q get bestfw.route)
    echo $LOCAL_ROUTER_TYPE
    if [ ! -z "$LOCAL_ROUTER_TYPE" ];
    then
      DEVICE_TYPE=$LOCAL_ROUTER_TYPE
    else
      uciup bestfw.route "$DEVICE_TYPE"
    fi
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

  set_system_name

  check_packages || install_packages
  check_packages || {
    echo "The packages can not install, please check internet connetion."
    exit
  }
  check_type
}

rebuild_wifi()
{
if [ "$HW" == "MiWiFi" ];
then
cat > /etc/config/${PRENAME}wireless << EOF
  config wifi-device 'radio0'
          option type 'mac80211'
          option channel '36'
          option hwmode '11a'
          option path 'pci0000:00/0000:00:00.0/0000:01:00.0'
          option htmode 'VHT80'
          option disabled '1'

  config wifi-device 'radio1'
          option type 'mac80211'
          option hwmode '11g'
          option path 'platform/10180000.wmac'
          option htmode 'HT20'
          option txpower '20'
          option channel '1'
          option country 'ES'
EOF
fi

if [ "$HW" == "TL-WR710N" ];
then
  MESH_RADIO="radio0"
  AP_RADIO="radio0"
  GW_ETH_CLIENTS='eth1'
  GW_ETH_MGMT=""
  OTHER_ETH_CLIENTS="eth1"
  OTHER_ETH_MGMT="eth0"
  MESH_MODE="adhoc"
  MESH_ID="C0:FF:EE:C0:FF:EE"
  BATADV_DEVICE="bat0"


cat > /etc/config/${PRENAME}wireless << EOF
config wifi-device 'radio0'
        option type 'mac80211'
        option hwmode '11g'
        option path 'platform/ar933x_wmac'
        option channel '9'
        option htmode 'HT40'
        option txpower '15'
        option country 'ES'
        option distance '100'
EOF
fi
}

define_batadv()
{
  cat > /etc/config/${PRENAME}batman-adv << EOF
config 'mesh' 'bat0'
        option 'aggregated_ogms'
        option 'ap_isolation' 1
        option 'bonding'
        option 'fragmentation' 1
        option 'gw_bandwidth'
        option 'gw_mode'
        option 'gw_sel_class'
        option 'log_level'
        option 'orig_interval' 1000
        option 'vis_mode'
        option 'bridge_loop_avoidance' 1
        option 'distributed_arp_table' 1
        option 'network_coding'
        option 'hop_penalty'
        option 'isolation_mark'
EOF

}

restart_services()
{
    /sbin/wifi reload
    /etc/init.d/network restart
}

spcecific_hardware()
{
  if [ "$HW" == "MiWiFi" ];
  then
    uciup network.lan.ifname eth0.3
    uciup network.lan_dev.name eth0.3
    ucidelete network.@switch_vlan[0]
    ucidelete network.@switch_vlan[0]
    ucidelete network.@switch_vlan[0]
    cat >> /etc/config/${PRENAME}network << EOF
config switch_vlan
        option device 'switch0'
        option vlan '1'
        option ports '1 2 3 6t'

config switch_vlan
        option device 'switch0'
        option vlan '2'
        option ports '4 6t'

config switch_vlan
        option device 'switch0'
        option vlan '3'
        option ports '0 6t'
EOF
  fi
}

client()
{

  ## Configurar bat0


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
  uciup network.vlanc.ifname "${BATADV_DEVICE}"

  # Network for clients
  uciup network.clients interface
  uciup network.clients.type 'bridge'
  uciup network.clients.proto 'none'
  uciup network.clients.ifname "vlanc ${OTHER_ETH_CLIENTS}"

  # VLAN for Manager
  uciup network.vlanm device
  uciup network.vlanm.type '8021ad'
  uciup network.vlanm.name 'vlanm'
  uciup network.vlanm.vid $MGMT_VLAN
  uciup network.vlanm.proto 'none'
  uciup network.vlanm.ifname "${BATADV_DEVICE}"

  # Network for Manager
  uciup network.mgmt interface
  uciup network.mgmt.type 'bridge'
  uciup network.mgmt.proto 'dhcp'
  uciup network.mgmt.ifname "vlanm ${OTHER_ETH_MGMT}"
  ucidelete network.mgmt.ipaddr
  ucidelete network.mgmt.netmask

  # MESH
  uciup wireless.batmesh wifi-iface
  ucicommit
  uciup wireless.batmesh.device $MESH_RADIO
  uciup wireless.batmesh.network 'batmesh'
  uciup wireless.batmesh.encryption 'none'
  uciup wireless.batmesh.mode $MESH_MODE
  if [ "$MESH_MODE" == "mesh" ];
  then
    uciup wireless.batmesh.mesh_id $MESH_ID
  else
    uciup wireless.batmesh.bssid $MESH_ID
    uciup wireless.batmesh.ssid $MESH_SSID
  fi
  uciup wireless.batmesh.ifname $MESH_IFNAME

  # AP
  uciup wireless.vap wifi-iface
  ucicommit
  uciup wireless.vap.device $AP_RADIO
  uciup wireless.vap.mode 'ap'
  uciup wireless.vap.encryption 'none'
  uciup wireless.vap.ssid $AP_SSID
  uciup wireless.vap.network 'clients'
  uciup wireless.vap.ifname $AP_IFNAME


  # DHCPs


  # firewall

  uciup firewall.@zone[0].network 'lan clients mgmt'

}

gateway()
{

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
  uciup network.vlanc.ifname "${BATADV_DEVICE}"

  # Network for clients
  uciup network.clients interface
  uciup network.clients.type 'bridge'
  uciup network.clients.proto 'static'
  uciup network.clients.ipaddr $CLIENT_IP
  uciup network.clients.netmask $CLIENT_NETMASK
  uciup network.clients.ip6assign '60'
  uciup network.clients.ifname "vlanc ${GW_ETH_CLIENTS}"

  # VLAN for Manager
  uciup network.vlanm device
  uciup network.vlanm.type '8021ad'
  uciup network.vlanm.name 'vlanm'
  uciup network.vlanm.vid $MGMT_VLAN
  uciup network.vlanm.proto 'none'
  uciup network.vlanm.ifname "${BATADV_DEVICE}"

  # Network for Manager
  uciup network.mgmt interface
  uciup network.mgmt.type 'bridge'
  uciup network.mgmt.proto 'static'
  uciup network.mgmt.ipaddr $MGMT_IP
  uciup network.mgmt.netmask $MGMT_NETMASK
  uciup network.mgmt.ip6assign '60'
  uciup network.mgmt.ifname "vlanm ${GW_ETH_MGMT}"

  # MESH
  uciup wireless.batmesh wifi-iface
  ucicommit
  uciup wireless.batmesh.device $MESH_RADIO
  uciup wireless.batmesh.network 'batmesh'
  uciup wireless.batmesh.encryption 'none'
  uciup wireless.batmesh.mode $MESH_MODE
  if [ "$MESH_MODE" == "mesh" ];
  then
    uciup wireless.batmesh.mesh_id $MESH_ID
  else
    uciup wireless.batmesh.bssid $MESH_ID
    uciup wireless.batmesh.ssid $MESH_SSID
  fi
  uciup wireless.batmesh.ifname $MESH_IFNAME

  # AP
  uciup wireless.vap wifi-iface
  ucicommit
  uciup wireless.vap.device $AP_RADIO
  uciup wireless.vap.mode 'ap'
  uciup wireless.vap.encryption 'none'
  uciup wireless.vap.ssid $AP_SSID
  uciup wireless.vap.network 'clients'
  uciup wireless.vap.ifname $AP_IFNAME


  # DHCPs
  uciup dhcp.clients dhcp
  uciup dhcp.clients.start $CLIENT_DHCP_START
  uciup dhcp.clients.limit $CLIENT_DHCP_END
  uciup dhcp.clients.leasetime '12h'
  uciup dhcp.clients.dhcpv6 'server'
  uciup dhcp.clients.ra 'server'
  uciup dhcp.clients.interface 'clients'
  uciup dhcp.clients.ra_management '1'

  uciup dhcp.mgmt dhcp
  uciup dhcp.mgmt.start $MGMT_DHCP_START
  uciup dhcp.mgmt.limit $MGMT_DHCP_END
  uciup dhcp.mgmt.leasetime '12h'
  uciup dhcp.mgmt.dhcpv6 'server'
  uciup dhcp.mgmt.ra 'server'
  uciup dhcp.mgmt.ra_management '1'
  uciup dhcp.mgmt.interface 'mgmt'

  # firewall

  uciup firewall.@zone[0].network 'lan clients mgmt'

}

initialize
define_batadv
rebuild_wifi

echo "Device type: "$DEVICE_TYPE
if [ $DEVICE_TYPE == "client" ];
then
  client
else
  gateway
fi

spcecific_hardware
ucicommit
restart_services
