#!/bin/bash

# Forked from  Max2Play WPS (Wifi Protected Setup) Auto Connection on Startup

# only run if there's no current wifi network configured
if [ "$(LANG=C && wpa_cli -iwlan0 list_networks | wc -l )" -eq "1" ]; then
    #Find a2.4Ghz Network
    wpa_cli -iwlan0 scan 
    sleep 1
    
    BSSID=$(/sbin/wpa_cli -iwlan0 scan_results | grep "WPS" | sort -r -k3 | cut -f1) 
    echo "Joining $BSSID"
    SUCCESS=$(wpa_cli -iwlan0 wps_pbc "$BSSID")
    sleep 15
    
    # Check for Entry in wpa_supplicant.conf
    VALIDENTRY=$(grep -i "^network=" /etc/wpa_supplicant/wpa_supplicant.conf | wc -l)
    
    # wpa_supplicant.conf should be modified in last 20 seconds by WPS Config
    MODIFIED=$(( `date +%s` - `stat -L --format %Y /etc/wpa_supplicant/wpa_supplicant.conf` ))
    
    if [ "$(echo "$SUCCESS" | grep 'OK' | wc -l)" -gt "0" -a "$VALIDENTRY" -gt "0" -a "$MODIFIED" -lt "20" ]; then
	echo "Joined AP $BSSID"
    	# Now Config File should be written    	
	wpa_cli -iwlan0 save_config
	systemctl restart wpa_supplicant-nl80211@wlan0.service
	echo "Attempting dhchp connection"
    	dhcpcd -n wlan0	
    else
    	echo "ERROR Completing WPS Auto Config"
    	echo "Response from 'wpa_cli -iwlan0 wps_pbc $BSSID' $SUCCESS"
    fi
else
    	echo "Network is already configured"
fi

