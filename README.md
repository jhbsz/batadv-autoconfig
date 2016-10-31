# Batadv-config

Aquest paquet serveix per autoconfigurar-se alguns tipus de maquinari (mirar l'apartat **maquinari suportat**), per poder crear una xarxa sense fils amb propietats de roaming. Utilitzant [BATMAN-adv](https://www.open-mesh.org/projects/batman-adv/wiki) un protocol de Capa 2.


## Compile version
### Install packages

* Afegir el paquet al fitxer de feeds.conf:
```
echo "src-git bfw https://github.com/agustim/batadv-autoconfig.git" >> feeds.conf
```
* Updatejar i instal·lar els nous paquets:
```
./script/feeds update -a
./script/feeds install -a
```
* Sel·leccionar el paquet a un make menuconfig
```
make menuconfig
Network -> batadv-config
```
* Compilar
```
make world
```

## Handmade version

Es possible instal·lar a mà el paquet, donat que en realitat son un conjunt d'scripts, principalment s'ha de gravar els fitxer de net/batadv-config/files/ a l'arrel del dispositiu.

```
scp -R net/batadv-config/files/* root@192.168.1.1:/
```

## Client or Gateway

Per defecte tots els trastos es configuren com clients, si volem posar-los com a gateway, només en pot haver-hi un, hem de canviar un registre del uci.

### Passar a Gateway

```
uci set bestfw.router=gateway
uci commit
/etc/init.d/batadv-config start
```
Amb això passarà a ser el Gateway i el DHCPserver de la xarxa.

### Passar a Client

```
uci set bestfw.router=client
uci commit
/etc/init.d/batadv-config start
```

És possible que quan es faci un canvi d'aquest sigui necessari reinicialitzar el router:

```
reboot
```

## Maquinari suportat

* TP-Link TL-WR710N : El dispositiu deixa el eth0 dintre del br-lan (192.168.1.1/24).
* Xiaomi miwifi
