# This config file is used to configure a PERSONA Demo kit network interface
# Properly configured the wireless is the WAN else the WAN port is WAN
# The drawBridge is in the router DMZ. 
# Address the drawBridge via the kit IP that you will set here.
# CURRENT LAN SIDE CONFIGURATION NOTES:
# LAN ROUTER:     10.0.242.1
# LAN drawBridge: 10.0.242.2
# LAN Aperio HUB: 10.0.242.3
# LAN MASK:  255.255.255.248
# (USE EXTRAORDINARY MEANS TO CHANGE THAT, MAKE NOTES HERE)

# ALL LINES MUST START WITH NVRAM SET AS SEEN BELOW
# ONLY EDIT THE VALUE AFTER THE EQUALS SIGN

# Set the kit IP Address subnet mask and gateway here.
# This is how the kit will appear to you on your network

nvram set wan_ipaddr=10.0.0.2
nvram set wan_netmask=255.255.255.0
nvram set wan_gateway=10.0.0.1

# If using DHCP ignore above and set below to DHCP instead of static
# Static is recomended

wan_proto=static

# The Kit can join a WPA/WPA2 PSK TKIP or AES network if properly configured here
# If you do not want the kit to join Wi-Fi and instead wish to use the WAN ethernet
# port on the Cisco E800 then leave this misconfigured to fail connection on your site

nvram set wl0_ssid=h3aj-guest
nvram set wl0_wpa_psk=henryfell

nvram commit