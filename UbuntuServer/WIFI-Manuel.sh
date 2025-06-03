#!/bin/bash
sudo pkill wpa_supplicant
sudo pkill dhclient
sudo ip link set wlp0s12f0 up
sudo wpa_supplicant -B -i wlp0s12f0 -c /etc/wpa_supplicant.conf
sudo dhclient wlp0s12f0
