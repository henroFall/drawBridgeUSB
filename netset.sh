#!/bin/bash


pathusb=/media/usb # do not change, managed by Linux
demoIP="10.0.242.1" # this is the LAN IP of the AAAPERIO router for updates to the WAN interface

sleep 10

function whereami {
        whereami=$(dirname $(find /usr/ -type f -name "IoTGateway.dll"))
        if [ -z "$whereami" ]
                then
                whereami=$(dirname $(find /opt/ -type f -name "IoTGateway.dll"))
        fi
}

function wheresmyvoice {
   ip addr show | awk '/inet.*brd/{print $NF; exit}'
}

function IPprefix_by_netmask () {
   c=0 x=0$( printf '%o' ${1//./ } )
   while [ $x -gt 0 ]; do
       let c+=$((x%2)) 'x>>=1'
   done
   echo /$c ;
}

getHostName() {
    cat /etc/hostname
}

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

function installCert() {
   cd $whereami/Certificates/
   unzip -o -j $pathusb/*.zip
   cp rootCA.cer /usr/local/share/ca-certificates/rootCA.crt
   update-ca-certificates
   cd $whereami
   rm -f appsettings.json.bak
   cp appsettings.json appsettings.json.bak
   if [ -z "$old_pw" ]
   then
      sed -i "s/Test1234/$cer_pw/g" appsettings.json
      sed -i "s/TestClient/$cer_pw/g" appsettings.json
      sed -i "s/client.pfx/ClientCert.pfx/g" appsettings.json
      echo $(date) "LAST OPERATION - LOADED FIRST CERT" >>$pathusb/log.txt
   else
      sed -i "s/$old_pw/$cer_pw/g" appsettings.json
      sed -i "s/client.pfx/ClientCert.pfx/g" appsettings.json
      echo $(date) "$hostn: LAST OPERATION - TRIED TO LOAD A SUBSEQUENT CERT" >>$pathusb/log.txt
   fi
}

##############
# Here we go #
##############
echo $(date) "$hostn: -------------------------------" >>$pathusb/log.txt
echo $(date) "$hostn: START OPERATION - USB DETECTED." >>$pathusb/log.txt
# This section goes after the basic configuration
hostn=$(getHostName)
if  [ -f "$pathusb/config.yaml" ]
    then
    echo Config file found...
    whereami
    if [ "$ip_lastgood" = "sure" ]
    then
      rm -f /etc/netplan/iotgateway.yaml
      cp $whereami/iotgateway.yaml.last /etc/netplan/iotgateway.yaml
      echo "LAST OPERATION - RESET TO LAST KNOWN GOOD."
      echo $(date) "$hostn: LAST OPERATION - RESET TO LAST KNOWN GOOD." >>$pathusb/log.txt
      netplan apply
      sleep 2
      shutdown now
    fi
    nic=$(wheresmyvoice)
    if [ -z "$nic" ]
        then
        nic="enp2s0" #Guessing. Shouldn't need to hit this part, more likely to get the wrong nic above than null
    fi
    echo Binding to network adapter $nic
    eval $(parse_yaml $pathusb/config.yaml)
    ip_maskc=$(IPprefix_by_netmask $ip_mask)
    ip_string="$ip_addr$ip_maskc"
    rm -f $whereami/iotgateway.yaml.last
    cp /etc/netplan/iotgateway.yaml $whereami/iotgateway.yaml.last
    echo Building netplan...
    echo "network:
    ethernets:
        $nic:
            dhcp4: $ip_dhcp
            addresses:
                    - $ip_string
            gateway4: $ip_gateway
            nameservers:
                      addresses: [$ip_dns]
    version: 2" >/etc/netplan/iotgateway.yaml

    echo $(date) "$hostn: LAST OPERATION - LOADED IP_ADDR: $ip_addr" >>$pathusb/log.txt
    echo $(date) "$hostn: LAST OPERATION - LOADED IP_MASK: $ip_mask" >>$pathusb/log.txt
    echo $(date) "$hostn: LAST OPERATION - WROTE IP_INFO : $ip_string" >>$pathusb/log.txt
    echo $(date) "$hostn: LAST OPERATION - LOADED IP_GATE: $ip_gateway" >>$pathusb/log.txt
    echo $(date) "$hostn: LAST OPERATION - LOADED IP_DNS : $ip_dns" >>$pathusb/log.txt
    netplan apply
else
    echo No Config file was found on the USB drive!
    echo $(date) "$hostn: LAST OPERATION - CONFIG FILE NOT FOUND" >>$pathusb/log.txt
fi

# This section goes after the certs
if compgen -G "$pathusb/*.pco" > /dev/null
    then
	echo $(date) "$hostn: LAST OPERATION - CERTTIFICATE FILES DETECTED" >>$pathusb/log.txt
    cd $whereami/Certificates/
    unzip -o -j $pathusb/*.pco
    cp rootCA.cer /usr/local/share/ca-certificates/rootCA.crt
    update-ca-certificates
    cd $whereami
    rm -f appsettings.json.bak
    cp appsettings.json appsettings.json.bak
    if [ -z "$old_pw" ]
    then
      sed -i "s/Test1234/$cer_pw/g" appsettings.json
      sed -i "s/TestClient/$cer_pw/g" appsettings.json
      sed -i "s/client.pfx/ClientCert.pfx/g" appsettings.json
      echo $(date) "$hostn: LAST OPERATION - LOADED FIRST CERT" >>$pathusb/log.txt
    else
      sed -i "s/$old_pw/$cer_pw/g" appsettings.json
      sed -i "s/client.pfx/ClientCert.pfx/g" appsettings.json
      echo $(date) "$hostn: LAST OPERATION - TRIED TO LOAD A SUBSEQUENT CERT" >>$pathusb/log.txt
    fi
fi

# This section does a major patch
if  [ -f "$pathusb/pco.patch" ]
    then
	echo $(date) "$hostn: LAST OPERATION - DRAWBRIDGE PATCH DETECTED" >>$pathusb/log.txt
    mv $pathusb/pco.patch $pathusb/pco.tar.gz
    systemctl stop pco-service.service
    systemctl stop IoTGateway.service
    tar -C $whereami -xvf $pathusb/pco.tar.gz
    rm -f $pathusb/pco.tar
    echo $(date) "$hostn: LAST OPERATION - PATCH APPLIED" >>$pathusb/log.txt
fi

# This section does an updater patch
if  [ -f "$pathusb/updater.patch" ]
    then
	echo $(date) "$hostn: LAST OPERATION - UPDATER WATCHUSB.SERVICE PATCH DETECTED" >>$pathusb/log.txt
    systemctl stop watchusb.service
    systemctl stop watchwatchusb.service
    mkdir $pathusb/updater
    tar -C $pathusb/updater -xvf $pathusb/updater.patch
    if [ -e $pathusb/updater/watchusb.service ]
     then
     cp $pathusb/updater/watchusb.service /lib/systemd/system/watchusb.service
     echo $(date) "$hostn: LAST OPERATION - UPDATER WATCHUSB.SERVICE PATCH APPLIED" >>$pathusb/log.txt
    fi
    if [ -e $pathusb/updater/watchwatchusb.service ]
     then
     cp $pathusb/updater/watchwatchusb.service /lib/systemd/system/watchwatchusb.service
     echo $(date) "$hostn: LAST OPERATION - UPDATER WATCHWATCHUSB.SERVICE PATCH APPLIED" >>$pathusb/log.txt
    fi
    if [ -e $pathusb/updater/netset.sh ]
     then
     cp $pathusb/updater/netset.sh $whereami/netset.sh
     echo $(date) "$hostn: LAST OPERATION - UPDATER NETSET PATCH APPLIED" >>$pathusb/log.txt
     chmod +x $whereami/netset.sh
    fi
    if [ -e $pathusb/updater/watchusb.py ]
     then
     cp $pathusb/updater/watchusb.py $whereami/watchusb.py
     echo $(date) "$hostn: LAST OPERATION - WATCHUSB APP PATCH APPLIED" >>$pathusb/log.txt
     chmod +x $whereami/watchusb.py
    fi
    echo $(date) "$hostn: LAST OPERATION - UPDATER PATCH APPLIED" >>$pathusb/log.txt
fi

# This section does a demo system router reconfig
if  [ -f "$pathusb/demokit.config" ]
    then
    sshpass -p "AAAPERIODEM0" ssh -o StrictHostKeyChecking=no root@$demoIP "$pathusb/demokit.config"
    sshpass -p "AAAPERIODEM0" ssh -o StrictHostKeyChecking=no root@$demoIP "reboot"
    echo $(date) "$hostn: LAST OPERATION - DEMO ROUTER CONFIGURED" >>$pathusb/log.txt
fi
echo Unmounting...
pumount usb
sleep 2
shutdown now
