#!/bin/bash

if [ -z "$1" ] || [ $1 == "undefined" ]; then
    echo "Error: db nodes are not set"
    exit 1
fi
if [ -z "$2" ] || [ $2 == "undefined" ]; then
    echo "Warning: cells are not set"
fi
if [ -z "$3" ] || [ $3 == "undefined" ]; then
    echo "Error: image version are not set"
    exit 1
fi
if [ -z "$4" ] || [ $4 == "undefined" ]; then
    type="bm" 
else
    type=$4
fi
if [ -z "$5" ] || [ $5 == "undefined" ]; then
    config="db2hc3" 
else
    config=$5
fi

. ../../exadata.env
if [ -z "$node_password"]; then
    echo node_password is not set
    exit 1
fi
if [ -z "$oeda_source_loc"]; then
    echo oeda_source_loc is not set
    exit 1
fi
if [ -z "$oeda_bm_target_loc"]; then
    echo oeda_bm_target_loc is not set
    exit 1
fi
if [ -z "$oeda_vm_target_loc"]; then
    echo oeda_vm_target_loc is not set
    exit 1
fi
if [ -z "$exadata_bm_download"]; then
    echo exadata_bm_download is not set
    exit 1
fi
if [ -z "$oeda_vm_target_loc"]; then
    echo oeda_vm_target_loc is not set
    exit 1
fi

ssh="ssh -o BatchMode=yes -o StrictHostKeyChecking=no"
scp="scp -o BatchMode=yes -o StrictHostKeyChecking=no"
echo "Exadata OEDA Install"
echo
echo "OEDA Install step 1: set up ssh passwordless connection to all db nodes and cells..."
echo ==================================================================
echo
for i in ${1//,/ } ${2//,/ }; do
    if ! $ssh $i echo -n > /dev/null 2>&1; then
        echo set up passwordless connection to $i...

expect <<- DONE
        spawn ssh-copy-id $i
        expect {
            "password: " { send "$node_password\r"; exp_continue }
        }
DONE

    fi
done

if [ "$type" = "vm" ]; then
    echo
    echo "OEDA Install step 1.5: switch_to_ovm on all db nodes..."
    echo ==================================================================
    echo
    for i in ${1//,/ }; do
        echo "switch_to_ovm on $i"
        echo $ssh $i "/opt/oracle.SupportTools/switch_to_ovm.sh"
        $ssh $i "/opt/oracle.SupportTools/switch_to_ovm.sh"
    done
    sleep 600
    for i in ${1//,/ }; do
        if ! $ssh $i echo -n > /dev/null 2>&1; then
            echo "need to wait more time for all db to come up"
            exit 1
        fi
    done
fi

echo
echo "OEDA Install step 2: reclaimdisks on all db nodes..."
echo ==================================================================
echo
for i in ${1//,/ }; do
    echo "reclaimdisks on $i"
    echo $ssh $i "/opt/oracle.SupportTools/reclaimdisks.sh -free -reclaim"
    $ssh $i "/opt/oracle.SupportTools/reclaimdisks.sh -free -reclaim"
done

echo
echo "OEDA Install step 3: copy OEDA to the first db node..."
echo ==================================================================
echo
for i in ${1//,/ }; do
    echo "copy OEDA to $i"
    target_loc=$oeda_bm_target_loc
    if [ "$type" = "vm" ]; then
        target_loc=$oeda_vm_target_loc
    fi
    echo $ssh $i "mkdir -p $target_loc"
    $ssh $i "mkdir -p $target_loc"
    echo $scp -r $oeda_source_loc/linux-x64 $i:$target_loc
    $scp -r $oeda_source_loc/linux-x64 $i:$target_loc
    break
done

echo
echo "OEDA Install step 4: copy downloaded files and patches to the first db node..."
echo ==================================================================
echo
for i in ${1//,/ }; do
    echo "copy downloaded files and patches to $i"
    if [ "$type" = "bm" ]; then
        echo $scp $exadata_bm_download/*.zip $i:$target_loc/linux-x64/WorkDir
        $scp $exadata_bm_download/*.zip $i:$target_loc/linux-x64/WorkDir
    else
        echo $scp $exadata_vm_download/*.zip $i:$target_loc/linux-x64/WorkDir
        $scp $exadata_vm_download/*.zip $i:$target_loc/linux-x64/WorkDir
    fi
    break
done

echo
echo "OEDA Install step 5: OEDA install on the first db node..."
echo ==================================================================
echo
for i in ${1//,/ }; do
    echo "OEDA install on $i"
    echo $ssh $i "cd $target_loc/linux-x64; ./install.sh -cf $config/Oracle_Linux_and_Virtualization_Group-ca-ex01.xml -r 1-17"
    $ssh $i "cd $target_loc/linux-x64; ./install.sh -cf $config/Oracle_Linux_and_Virtualization_Group-ca-ex01.xml -r 1-17"
    break
done

