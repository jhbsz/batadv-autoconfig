#!/bin/sh

## Update packages
opkg Update

opkg install batctl kmod-batman-adv

## Configurar bat0

uci set batman-adv.mesh=bat0

#uci set batman-adv.mesh.bat0.aggregated_ogms=
#uci set batman-adv.mesh.bat0.ap_isolation=
#uci set batman-adv.mesh.bat0.bonding=
#uci set batman-adv.mesh.bat0.fragmentation=
#uci set batman-adv.mesh.bat0.gw_bandwidth=
#uci set batman-adv.mesh.bat0.gw_mode=
#uci set batman-adv.mesh.bat0.gw_sel_class=
#uci set batman-adv.mesh.bat0.log_level=
#uci set batman-adv.mesh.bat0.orig_interval=
#uci set batman-adv.mesh.bat0.vis_mode=
#uci set batman-adv.mesh.bat0.bridge_loop_avoidance=
#uci set batman-adv.mesh.bat0.distributed_arp_table=
#uci set batman-adv.mesh.bat0.multicast_mode=
#uci set batman-adv.mesh.bat0.network_coding=
#uci set batman-adv.mesh.bat0.hop_penalty=
#uci set batman-adv.mesh.bat0.isolation_mark=
