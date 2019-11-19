#!/bin/bash
SERVICES="ModemManager lightdm hostapd variscite-bluetooth apt-daily.timer apt-daily apt-daily-upgrade.timer apt-daily-upgrade NetworkManager-wait-online"
TWOG=${1:-1}    # number of 2.4 GHz antennas (default: 1)
FIVG=${2:-0}    # number of 5.8 GHz antennas (default: 0)
# setup hostname to match serial number read from fuses
sn1=`cat /sys/fsl_otp/HW_OCOTP_CFG0`
sn2=`cat /sys/fsl_otp/HW_OCOTP_CFG1`
printf 'IMX6%0.8x%0.8x\n' $sn1 $sn2 > /etc/hostname
cat /etc/hostname
# change root password
passwd
# disable services that slow down boot and interfere with operations
for s in $SERVICES ; do
	do systemctl disable --now ${s} ; done
done
# configure wifi chip and load initial firmware
( cd /usr/sbin/wlconf && ./configure-device.sh ) <<EOF
y
1837
n
${TWOG}
${FIVG}
y
EOF
