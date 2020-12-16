USBWatcher Readme

1. Create a file config.yaml on the root of the memory stick with the contents below the ######
2. If config.yaml exists, I will grab the variables, go to work, and shut down the Gateway.
3. To load certs, create any *.zip file on the root of the memory stick. 
  ** I'm not too smart here - if a .zip exists, i will extract it all to the Certificates folder
  ** and go nuts from there. 
  ** If no .zip exists, then I don't do anything about certs.   
4. To update the application, call for help - but yes, I can update the app.


Note that you must insert the memory stick within 5 minutes of boot up or the monitor will shut down.


###########################################################################################
# ip_dhcp true or false
:ip_dhcp: 'false'

# ip_addr your static IP (ignored w/ dhcp true)
:ip_addr: '192.168.1.110'

# ip_mask your static IP subnet mask (ignored w/ dhcp true)
:ip_mask: '255.255.255.0'

# ip_gateway your static IP gateway (ignored w/ dhcp true)
:ip_gateway: '192.168.201.1'

# ip_dns your static IP dns (ignored w/ dhcp true)
:ip_dns: '1.1.1.1'

# cer_pw your password for your certificate
:cer_pw: 'Abc321'

# ip_lastgood sure or false
# (ALWAYS leave this false unless you really messed up)
# If you think the best thing to do is to copy back the 
# file I just moved on the last run, set this value to
# sure . Do not set TRUE, set sure .
# (ALWAYS leave this false unless you really messed up)
:ip_lastgood: 'false'