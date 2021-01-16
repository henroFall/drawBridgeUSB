# drawBridgeUSB ReadMe
This service performs headless installs and updates to the appliance. This is PRE RELEASE and will be ultimately replaced in 2021. 

If you are using Henry's Gateway installer from 1/10/2021 or later, this utility is bundled. You do not need to run this. 

Do run this on any generic device, or device instaled prior to 1/10/2021, or to update a device, if you wish (there are other means to do that).

Install locally on your NUC with this copy/paste. 
Note this is all one line, select the whole string of text:

> wget -nv -N https://raw.githubusercontent.com/henroFall/drawBridgeUSB/main/drawBridgeUSBinstall.sh && sudo chmod +x drawBridgeUSBinstall.sh && sudo ./drawBridgeUSBinstall.sh && rm drawBridgeUSBinstall.sh

With this application, you can configure the network, install certificates, and perform software updates to the device and some demo kits. After you install and reboot, this service will run for exactly 5 minutes and monitor for USB stick insertion. If you are +5 minutes from boot time, you must first reboot the device to perform this procedure. 

A log.txt is created on the memory stick. 

You can perform any of these actions on their own. You can place any one or all three of these files on the stick for the operations to occur. The script attempt to process each step in sequence.

## Network Update Feature
Use the config.yaml file from this repo as a template and and copy it to the root of a USB stick. Edit the file with the obvious values that you want to configure the NUC with. Within 5 minutes of boot, simply insert the USB drive into the NUC. With this you can configure all parameters for the network interface of the NUC.

## Certificate Installer
You will run the certmaker script on the application server as usual. You will then retrieve the _[word-of-the-day]-files.pco_ file from the server and copy it to the root of the memory stick.
The USB updater service will look for any *.pco file on the root of the stick, extract the contents to the /Certificates area on the Drawbridge device and installs them. The entire process is automatic after you put the .pco file onto the USB stick.

## Demo Kit Updater
AAAPERIO kit type updates to the Cisco E800 Router are supported. Place a _demokit.config_ file on the root of the USB stick that follows the template of the file in this repo. If this file exists, all commands will be executed on the router and it will then reboot. If no _demokit.config_ file exists then the router will *not* reboot.

## Full Software Update
If a file named pco.patch exists on the root of the memory stick, the entire contents will be extracted and dumpped right on top of the application folder. This is actually super dangerous and probably should never be done. It seemed like a good idea at the time.
 
## Updater Software Update
If a file named updater.patch exists on the root of the memory stick, the entire contents will be extracted to a subfolder and then each file in the updater package will be overwritten by a new file if it exists in the extracted folder. This also sounds dumb until the other side can validate the package.

...Which would be easy. I should do that if this lingers...

## Completion
You will know this worked when the NUC powers itself off about 15 seconds after you insert the stick. If the NUC never powers off, you probably missed the 5 minute window, or something catastrohic happened. You can look on the USB stick for a log file.
