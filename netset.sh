#!/bin/bash
pathusb=/media/usb
sleep 5

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
   sudo cp rootCA.cer /usr/local/share/ca-certificates/rootCA.crt
   sudo update-ca-certificates
   cd $whereami
   if [ -z "$old_pw" ]
   then
      sed -i "s/Test1234/$cer_pw/g" appsettings.json
      sed -i "s/TestClient/$cer_pw/g" appsettings.json
	  echo $(date -u) "LAST OPERATION - LOADED FIRST CERT" >>$pathusb/log.txt
   else
      sed -i "s/$old_pw/$cer_pw/g" appsettings.json
	  echo $(date -u) "LAST OPERATION - TRIED TO LOAD A SUBSEQUENT CERT" >>$pathusb/log.txt
   fi
   
}

if  [ -f "$pathusb/config.yaml" ]
    then
    whereami
    nic=$(wheresmyvoice)
    if [ -z "$nic" ]
        then
        nic="enp2s0" #Pure guess. Shouldn't need to hit this part, likely to get wrong nic over no nic.
    fi

    eval $(parse_yaml $pathusb/config.yaml)
    ip_maskc=$(IPprefix_by_netmask $ip_mask)
    ip_string="$ip_addr$ip_maskc"
    if [ "$ip_lastgood" = "sure" ]
    then
      rm -f /etc/netplan/iotgateway.yaml
      cp $whereami/iotgateway.yaml.last /etc/netplan/iotgateway.yaml
      echo $(date -u) "LAST OPERATION - RESET TO LAST KNOWN GOOD." >$pathusb/log.txt
      netplan apply
	  sleep 2
      shutdown now
      exit
    fi
    rm -f $whereami/iotgateway.yaml.last
    cp /etc/netplan/iotgateway.yaml $whereami/iotgateway.yaml.last

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

    echo $ip_string >$whereami/grue.txt
    echo $(date -u) "LAST OPERATION - LOADED IP_ADDR: $ip_addr" >$pathusb/log.txt
    echo $(date -u) "LAST OPERATION - LOADED IP_MASK: $ip_mask" >>$pathusb/log.txt
    echo $(date -u) "LAST OPERATION - WROTE IP_INFO : $ip_string" >>$pathusb/log.txt
    echo $(date -u) "LAST OPERATION - LOADED IP_GATE: $ip_gateway" >>$pathusb/log.txt
    echo $(date -u) "LAST OPERATION - LOADED IP_DNS : $ip_dns" >>$pathusb/log.txt
    netplan apply
    shutdown now
else 
    echo $(date -u) "LAST OPERATION - CONFIG FILE NOT FOUND" >>$pathusb/log-error.txt
fi


if  [ -f "$pathusb/*.zip" ]
    then
	installCert
fi
	
if  [ -f "$pathusb/pco.patch" ]
    then
	mv $pathusb/pco.patch $pathusb/pco.tar
	systemctl stop pco-service.service
	systemctl stop IoTGateway.service
	tar -C $whereami -xvf $pathusb/pco.tar
	rm -f $pathusb/pco.tar
	echo $(date -u) "LAST OPERATION - PATCH APPLIED" >>$pathusb/log-patch.txt
else
	echo $(date -u) "LAST OPERATION - NO PATCH AVAILABLE" >>$pathusb/log.txt
fi

umount /media/usb
shutdown now