# drawBridgeUSB ReadMe
This service performs headless installs and updates to the appliance. This is PRE RELEASE and will be ultimately replaced in 2021. 

Install locally on your NUC with this copy/paste. 
Note this is all one line, select the whole string of text:

> wget -N https://raw.githubusercontent.com/henroFall/drawBridgeUSB/main/drawBridgeUSBinstall.sh && sudo chmod +x drawBridgeUSBinstall.sh && sudo ./drawBridgeUSBinstall.sh

With this application, you can configure the network, install certificates, and perform software updates to the device. After you install and reboot, this service will run for exactly 5 minutes and monitor for USB stick insertion. If you are +5 minutes from boot time, you must first reboot the device to perform this procedure. 

A log.txt is created on the memory stick.

You can perform any of these actions on their own. You can place any one or all three of these files on the stick for the operations to occur. The script will process 1, 2, or 3 steps all at once. 

## Network Update Feature
After you install, take the config.yaml file from this repo and copy it to the root of a USB stick. Edit the file with the obvious values that you want to configure the NUC with. Within 5 minutes of boot, simply insert the USB drive into the NUC. 

You will know this worked when the NUC powers itself off about 15 seconds after you insert the stick. If the NUC never powers off, you probably missed the 5 minute window.

## Certificate Installer
You will run the certmaker script on the application server as usual. You will then retrieve the _[word-of-the-day]-files.pco_ file from the server and copy it to the root of the memory stick.
The USB updater service will look for any *.pco file on the root of the stick, extract the contents to the /Certificates area on the Drawbridge device and installs them. The entire process is automatic after you put the .pco file onto the USB stick.

## Full Software Update
If a file named pco.patch exists on the root of the memory stick, the entire contents will be extracted and dumpped right on top of the /IoTGateway folder. This is actually super dangerous and probably should never be done. It seemed like a good idea at the time.
 
