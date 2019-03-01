#!/bin/bash
sn1=`cat /sys/fsl_otp/HW_OCOTP_CFG0 | cut -c3-`
sn2=`cat /sys/fsl_otp/HW_OCOTP_CFG1 | cut -c3-`
echo "IMX6${sn1}${sn2}" > /etc/hostname
passwd
( cd /usr/sbin/wlconf && ./configure-device.sh ) <<EOF
y
1837
n
1
0
y
EOF
