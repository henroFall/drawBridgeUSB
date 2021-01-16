#!/bin/bash
# usbWatch Installer
netsetPullSpot="https://raw.githubusercontent.com/henroFall/drawBridgeUSB/main/netset.sh"

check_exit_status() {
    if [ $? -eq 0 ]
    then
        echo
       #echo -e "\e[93mSuccess\e[0m"
       #echo
    else
      echo
      echo -e "\e[93mERROR Process Failed!\e[0m"
      echo
      if [[ $1 == '-a' ]]
      then
        echo -e "\e[41m AUTO MODE IS ENABLED, EXITING.. \e[0m"
        echo
        exit 1
      else
        read -p "The last command exited with an error. Exit script? (yes/no)? " answer
        if [ "$answer" == "yes" ]
        then
          exit 1
        fi
      fi
    fi
}
function getHostName {
    cat /etc/hostname
}

function setHostName {
#Assign existing hostname to $hostn
hostn=$(getHostName)

echo
echo -e "\e[97mYou now have the opportunity to change the hostname of the Gateway."
echo -e "\e[97mThe existing hostname is \e[44m$hostn\e[0m."
echo
echo -e "\e[97mEnter new hostname for this Gateway device, or press <ENTER> to leave it unchanged [$hostn]: \e[0m"
read newhost
if [ -z "$newhost" ]
 then
 newhost=$hostn
 echo -e "The Gateway hostname was not changed. Hostname remains $newhost.\e[0m"
 else
 #change hostname in /etc/hosts & /etc/hostname
 sed -i "s/$hostn/$newhost/g" /etc/hosts
 sed -i "s/$hostn/$newhost/g" /etc/hostname
 #display new hostname
 echo -e "\e[97Your new hostname is $newhost, and will take effect on the next reboot.\e[0m"
 echo
fi
check_exit_status
check_debug $1
}

function setTimeZone {
timedatectl set-timezone $(tzselect)
echo
echo "The Time Zone is:"
timedatectl
check_debug $1
}

function whereami {
        echo "Gateway usbWatch Installer: Searching for install location."
        if [[ -d "/opt/amt/IoTGateway" ]]
         then
         whereami="/opt/amt/IoTGateway"
        fi
        if [[ -d "/usr/local/bin/IoTGateway" ]]
         then
         whereami="/usr/local/bin/IoTGateway"
        fi
        if [ -z "$whereami" ]
                then
                echo "PERSONA Gateway is NOT installed here. Exiting."
                exit 1
        fi
}

whereami
echo Installing PCO Drawbridge Gateway USB Monitor...
if  [[ $1 != 'dovetail' ]]
then
 setHostName
 setTimeZone
fi
apt update
check_exit_status
apt -y install ca-certificates unzip sshpass python3-pip ipcalc exfat-fuse exfat-utils pmount usbmount dos2unix
check_exit_status
pip3 install pyudev
check_exit_status
echo "Building UDEV override to automount USB drives..."
mkdir -p /etc/systemd/system/systemd-udevd.service.d
echo "[Service]
MountFlags=shared" > /etc/systemd/system/systemd-udevd.service.d/override.conf
check_exit_status
systemctl daemon-reload
check_exit_status
service systemd-udevd --full-restart
check_exit_status
cd $whereami
check_exit_status
echo "Pulling main script..."
wget -nv "$netsetPullSpot" -O netset.sh
check_exit_status
chmod +x netset.sh
check_exit_status
apt -y --fix-broken install
check_exit_status
echo "Now building the app file..."
echo "#!/usr/bin/env python

import functools
import os.path
import pyudev
import subprocess
import time

def main():
  time.sleep(5)
  if os.path.isfile('/media/usb/config.yaml'):
    subprocess.run(['/bin/bash', './netset.sh'])
  else
    timeout = 300   # [seconds]
    timeout_start = time.time()
    while time.time() < timeout_start + timeout:
      BASE_PATH = os.path.abspath(os.path.dirname(__file__))
      path = functools.partial(os.path.join, BASE_PATH)
      call = lambda x, *args: subprocess.call([path(x)] + list(args))

      context = pyudev.Context()
      monitor = pyudev.Monitor.from_netlink(context)
      monitor.filter_by(subsystem='usb')
      monitor.start()

      for device in iter(monitor.poll, None):
        subprocess.run(['/bin/bash', './netset.sh'])

if __name__ == '__main__':
    main()" >$whereami/watchusb.py
check_exit_status
echo "#!/bin/bash
sleep 305
sudo systemctl stop watchusb.service " >$whereami/watchwatchusb.sh
check_exit_status
chmod +x watchwatchusb.sh
check_exit_status
chmod +x $whereami/watchusb.py
check_exit_status
echo "Creating Service file 1/2..."
echo "[Unit]
Description=drawBridge USB Watcher Service

[Service]
Type=simple
ExecStart=/usr/bin/python3 $whereami/watchusb.py
WorkingDirectory=$whereami
User=root
Restart=no

[Install]
WantedBy=multi-user.target" >$whereami/watchusb.service
check_exit_status
echo "Creating Service file 2/2..."
echo "[Unit]
Description=drawBridge USB Watcher Shutdown Watchdog

[Service]
Type=simple
ExecStart=$whereami/watchwatchusb.sh
WorkingDirectory=$whereami
User=root
Restart=no

[Install]
WantedBy=multi-user.target" >$whereami/watchwatchusb.service
check_exit_status


cd $whereami/Certificates

if [ -f "/etc/netplan/iotgateway.yaml" ] ; then
cp /etc/netplan/iotgateway.yaml $whereami/iotgateway.yaml.org
fi
check_exit_status
cp $whereami/watchusb.service /lib/systemd/system/watchusb.service
cp $whereami/watchwatchusb.service /lib/systemd/system/watchwatchusb.service
check_exit_status
systemctl daemon-reload
check_exit_status
systemctl enable watchusb.service
check_exit_status
systemctl enable watchwatchusb.service
check_exit_status
systemctl start watchusb.service
check_exit_status
systemctl start watchwatchusb.service
check_exit_status
passwd amt
echo Press the enter key to reboot, or CTRL+C to stay in this session.
read
reboot
