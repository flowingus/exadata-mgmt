#!/bin/bash

if [ -z "$1" ] || [ $1 == "undefined" ]; then
    echo "Warning: db nodes are not set"
fi
if [ -z "$2" ] || [ $2 == "undefined" ]; then
    echo "Warning: cells are not set"
fi
if [ -z "$3" ] || [ $3 == "undefined" ]; then
    echo "Error: image version are not set"
    exit 1
fi

. ../../exadata.env
if [ -z "$ilom_password"]; then
    echo ilom_password is not set
    exit 1
fi
if [ -z "$ilom_password2"]; then
    echo ilom_password2 is not set
    exit 1
fi


echo "Exadata PXE Install"
echo PXE Install step 1: install Exadata $3 on db nodes...
echo =====================================================
echo
for i in ${1//,/ }; do
    echo install Exadata $3 on db node: $i
    echo ------------------------------------------------------------------------------- 
    echo ssh ca-sysinfra606 "cd /service/tftpboot/pxelinux.cfg; cp -f db.$3 $i"
    ssh ca-sysinfra606 "cd /service/tftpboot/pxelinux.cfg; cp -f db.$3 $i"
    echo ipmitool -I lanplus -H ${i}m -U root -P \*\*\*\*\*\* sunoem cli "set /host boot_device=pxe" "reset -script /system"
    if ! ipmitool -I lanplus -H ${i}m -U root -P $ilom_password sunoem cli "set /host boot_device=pxe" "reset -script /system"; then
        echo ipmitool -I lanplus -H ${i}m -U root -P \*\*\*\*\*\* sunoem cli "set /host boot_device=pxe" "reset -script /system"
        ipmitool -I lanplus -H ${i}m -U root -P $ilom_password2 sunoem cli "set /host boot_device=pxe" "reset -script /system"
    fi
done

echo
echo PXE Install step 2: install Exadata $3 on cells...
echo ==================================================
for i in ${2//,/ }; do
    echo install Exadata $3 on cell: $i
    echo ------------------------------------------------------------------------------- 
    echo ssh ca-sysinfra606 "cd /service/tftpboot/pxelinux.cfg; cp -f cell.$3 $i"
    ssh ca-sysinfra606 "cd /service/tftpboot/pxelinux.cfg; cp -f cell.$3 $i"
    echo ipmitool -I lanplus -H ${i}m -U root -P \*\*\*\*\*\* sunoem cli "set /host boot_device=pxe" "reset -script /system"
    ipmitool -I lanplus -H ${i}m -U root -P $ilom_password sunoem cli "set /host boot_device=pxe" "reset -script /system"
done

echo
echo waiting about one hour for the pxe installation...
date

while true; do
    echo -n \*
    sleep 60
    tobreak=true
    for i in ${1//,/ } ${2//,/ }; do
        if ! ping -c3 $i > /dev/null 2>&1; then
            tobreak=false
            break
        fi
    done
    if $tobreak; then
        break
    fi
done

echo done!
date
echo

