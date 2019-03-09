#!/bin/bash
SERVICES="ModemManager lightdm"
sn1=`cat /sys/fsl_otp/HW_OCOTP_CFG0`
sn2=`cat /sys/fsl_otp/HW_OCOTP_CFG1`
printf 'IMX6%0.8x%0.8x\n' $sn1 $sn2 > /etc/hostname
cat /etc/hostname
passwd
for s in $SERVICES ; do
	for c in stop disable ; do systemctl ${c} ${s} ; done
done
( cd /usr/sbin/wlconf && ./configure-device.sh ) <<EOF
y
1837
n
1
0
y
EOF
