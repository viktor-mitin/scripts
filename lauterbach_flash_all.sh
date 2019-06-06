#!/bin/sh

#This script flashes all the files for the RCAR SK
#
#Input parameters:
#     T32_DIR - trace32 installation directory
#     SCRIPT_TO_RUN - trace32 cmm script to run

T32_DIR=/home/c/t32
SCRIPT_TO_RUN="$T32_DIR"/10_LauterBach\(Trace32\)/sk-h3-flashall.cmm


T32_BIN_DIR="$T32_DIR"/bin/pc_linux64

# string example:
#Jun  4 14:27:18 3489 kernel: [13632.593589] usb 2-5: Product: Lauterbach PowerDebug Pro
STR=$(cat /var/log/kern.log | grep Lauterbach | tail -n 1 | cut -d ' ' -f 9)
if [ -z "$STR" ] ; then
    echo "Error: Lauterbach is not connected, exit."
    return 1
fi

BUS=$(echo "$STR" | cut -d '-' -f 1)
if [ -z "$BUS" ] ; then
    echo "Error: cannot find Lauterbach usb bus number, exit."
    return 2
fi

DEV=$(echo "$STR" | cut -d '-' -f 2 | sed 's/://')
if [ -z "$BUS" ] ; then
    echo "Error: cannot find Lauterbach usb device number, exit."
    return 3
fi

echo "Found Lauterbach on the bus $BUS, device $DEV"

#Udevadm test must run with root permissions, otherwise it will not work properly
sudo udevadm test /sys/devices/pci0000:00/0000:00:14.0/usb"$BUS"/"$BUS"-"$DEV" >/dev/null 2>&1
if [ $? -ne 0 ] ; then
    echo "Error: udevadm test failed, exit."
    return 4
fi

cd $T32_BIN_DIR
if [ $? -ne 0 ] ; then
    echo "Error: cannot find t32 source directory, exit."
    return 5
fi

if [ ! -f "$SCRIPT_TO_RUN" ] ; then
    echo "Error: cannot find cmm script to run, exit."
    return 6
fi

./t32marm64-qt -s "$SCRIPT_TO_RUN" &

#Close the t32 GUI window when flashing is done
#Note: t32 ignores SIGTERM during flash operation
while true ; do
    sleep 3
    pkill t32marm64 || break
done

