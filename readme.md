# Iris 2 Debian Development Image

This is a comfortable development image for Iris 2 hardware that makes it easy to develop.  It includes most of the features common to desktop development workstations.

## Build recovery SD image

 1. make all

The resulting recovery image will be found ./output/

## Installation on Iris system

 1. Prepare the recovery SD image
 1. set SW1 to SD and insert recovery mmc card into slot, power up
 1. login with root:root
```
debian-install.sh -b dart -t cap
```
 4. power off, set SW1 to EMMC and remove recovery mmc card, power up
 1. login with root:root
```
./postinstall.sh
```
The hostname matches the serial number of the modem, you can get it from `/etc/hostname`

 6. enable wifi and pick an access point
```
nmcli d wifi list
nmcli d wifi connect "your SSID" password "your PSK"
```
At this point, your system is setup.  To login remotely via ssh, you will need a pre-shared key.
