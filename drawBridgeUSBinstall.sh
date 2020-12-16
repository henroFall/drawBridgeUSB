#!/bin/bash
# usbWatch Installer

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

function whereami {
        whereami=$(dirname $(find /usr/ -type f -name "IoTGateway.dll"))
        if [ -z "$whereami" ]
                then
                whereami=$(dirname $(find /opt/ -type f -name "IoTGateway.dll"))
        fi
}

echo Installing PCO Drawbridge Gateway USB Monitor...
apt update
check_exit_status
apt install -y ca-certificates unzip python3-pip ipcalc
check_exit_status
pip3 install pyudev
check_exit_status

whereami
cd $whereami
echo Getting USBMount installer...
wget "http://www.personacampus.us/IoTGateway/usbmount_0.0.24_all.deb" -O usbmount_0.0.24_all.deb
check_exit_status
wget https://raw.githubusercontent.com/henroFall/drawBridgeUSB/main/netset.sh -O netset.sh
check_exit_status
chmod +x netset.sh
check_exit_status
dpkg -i usbmount_0.0.24_all.deb
apt --fix-broken install
check_exit_status

echo "Building app files..."
echo "#!/usr/bin/env python

import functools
import os.path
import pyudev
import subprocess
import time

def main():
  timeout = 300   # [seconds]
  timeout_start = time.time()
  while time.time() < timeout_start + timeout:

    if os.path.isfile('$whereami/grue.txt'):
      os.remove('$whereami/grue.txt')
      return
    BASE_PATH = os.path.abspath(os.path.dirname(__file__))
    path = functools.partial(os.path.join, BASE_PATH)
    call = lambda x, *args: subprocess.call([path(x)] + list(args))

    context = pyudev.Context()
    monitor = pyudev.Monitor.from_netlink(context)
    monitor.filter_by(subsystem='usb')
    monitor.start()

    for device in iter(monitor.poll, None):
        call('netset.sh')
        if os.path.isfile('$whereami/grue.txt'):
         break

if __name__ == '__main__':
    main()" >$whereami/watchusb.py
check_exit_status
chown +x $whereami/watchusb.py
check_exit_status

echo "[Unit]
Description=PERSONA USB Watcher Service

[Service]
Type=simple
ExecStart=/usr/bin/python3 $whereami/watchusb.py
WorkingDirectory=$whereami
User=root
Restart=no

[Install]
WantedBy=multi-user.target" >$whereami/watchusb.service
check_exit_status

echo "#!/bin/bash
sleep 300
sudo systemctl stop watchusb.service " >$whereami/watchwatchusb.sh
check_exit_status
chmod +x watchwatchusb.sh

echo "[Unit]
Description=PERSONA USB Watcher Shutdown Watchdog 

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


cp etc/netplan/iotgateway.yaml $whereami/iotgateway.yaml.org
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
echo pausing before reboot
read