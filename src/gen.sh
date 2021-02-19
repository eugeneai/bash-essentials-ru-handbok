#!/bin/bash

etc="./etc"
nwork="$etc/network"

if [ -e setup.conf ]; then
    source setup.conf
else
    echo "Файл настроек не найден!"
    exit 1
fi

echo "Название домена кластера: $NAMEDDOMAIN"

mpifile="$etc/nodes.conf"
namedfile="$etc/cluster-named.conf"

echo "" > $mpifile
echo "" > $namedfile

routeripv4=$NETPREF.$GWSUFF

echo "# ~/cluster/cluster-named.conf" >> $namedfile
echo "# @ = example.com" >> $namedfile
echo "# узел-маршрутизатор" >> $namedfile
echo "gw             IN  A       $routeripv4" >> $namedfile
echo "gw             IN  AAAA    $IPV6GW" >> $namedfile
echo "# Список узлов" >> $namedfile

input="cluster.conf"
# Чтение строк из файла со списком узлов

totslots=0

while IFS= read -r line
do
    name=""
    mac=$(echo $line | cut -f 1 -d " ")
    node=$(echo $line | cut -f 2 -d " ")
    num=$(echo $line | cut -f 3 -d " ")
    name=$(echo $line | cut -f 4 -d " ")
    echo "Обрабатываем узел $mac $node"

    if [ ! -z "$name" ] ; then
        echo "Узел называется $name "
    fi

    nodename="$HOSTNAMEPREF$node"

    # /etc/hostname
    file="$etc/hostname-$nodename"
    echo "$nodename" > $file

    # /etc/hosts

    file="$etc/hosts-$nodename"
    ulaip=$ULAPREFIX$V6NET:$node
    globip=$GLOBPREFIX$V6NET:$node
    # Локальные настройки
    echo "127.0.0.1 localhost localhost.localdomain" > $file
    echo "127.0.1.1 $name $nodename" >> $file
    l1=""
    l16=""
    l1g=""
    if [ ! -z "$name" ] ; then
        l1="$name.localdomain"
        l16="$name-6"
        l1g="$name-g"
    fi
    echo "127.0.1.2 $l1 $nodename.localdomain" >> $file
    echo "::1 localhost localhost.localdomain $name $nodename $l1 $nodename.localdomain" >> $file
    echo "$ulaip $nodename-6 $l16" >> $file
    echo "$globip $nodename-g $l1g" >> $file
    # Маршрутизаторы
    echo "$routeripv4 gw $HOSTNAMEPREF$GWSUFF" >> $file
    echo "$ULAPREFIX$V6NET:$GWSUFF gw $HOSTNAMEPREF$GWSUFF" >> $file

    # /etc/nodes   # MPI node list
    echo "$nodename slots=$num" >> $mpifile
    totslots=$((totslots+num))


    file="$nwork/20-wired-$nodename.network"
    # /etc/systemd/network/50-wired-nodename.network

    nodeipv4=$NETPREF.$node

    echo "# /etc/systemd/network/20-wired-$nodename.network" > $file
    echo "[Match]" >> $file
    echo "MACAddress=$mac" >> $file
    echo "[Network]" >> $file
    echo "Domains=localdomain $NAMEDDOMAIN" >> $file
    echo "IPForward=yes" >> $file
    echo "DNS=$DNSV4" >> $file
    echo "# Также позволить узлам настраиваться самостоятельно" >> $file
    echo "IPv6AcceptRA=yes" >> $file
    echo "[Address]" >> $file
    echo "Address=$nodeipv4" >> $file
    echo "Address=$ulaip/$ULAMASK" >> $file
    echo "Address=$globip/$IPV6GLOBMASK" >> $file
    echo "[Route]" >> $file
    echo "Gateway=$routeripv4" >> $file
    echo "Destination=0.0.0.0" >> $file
    echo "[Route]" >> $file
    echo "Gateway=$IPV6GW" >> $file
    echo "# fc0::/7 включает в себя $ulaip/$IPV6GLOBMASK" >> $file
    echo "Destination=fc0::/7" >> $file
    echo "[Route]" >> $file
    echo "Gateway=$IPV6GW" >> $file
    echo "# 2000::/3 включает в себя весь глобальный IPv6 Интернет" >> $file
    echo "Destination=2000::/3" >> $file
    echo "[IPv6AcceptRA]" >> $file
    echo "UseDNS=yes" >> $file
    echo "UseDomain=yes" >> $file

    # /etc/cluster-named.conf

    echo "$nodename        IN  A       $nodeipv4" >> $namedfile
    echo "$nodename        IN  AAAA    $ulaip" >> $namedfile
    echo "$nodename-g      IN  AAAA    $globip" >> $namedfile
    # Если указано специальное имя для узла, то добавляются эти записи
    if [ ! -z "$name" ] ; then
        echo "$name        IN  CNAME   $nodename.$NAMEDDOMAIN" >> $namedfile
        echo "$name-g      IN  CNAME   $nodename-g.$NAMEDDOMAIN" >> $namedfile
    fi

done < "$input"


echo "# Всего ядер - $totslots" >> $mpifile
echo "# Всего ядер - $totslots !"
