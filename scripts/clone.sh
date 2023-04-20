#!/bin/bash
set -e
CY='\x1b[33m'; CM='\x1b[36m'; CR='\x1b[0m'
[ $EUID -ne 0 ] && echo "Please run as root!" && exit 1
[[ $# < 2 ]] && echo "Usage: $0 <dev> <imgfile> [zip=none/min/med/max]" && exit 1
ext=".wim"
[[ "$2" = *.wim ]] && img="$2" || img="$2$ext"
[ -e "$img" ] && echo "Error: File exists" && exit 2

cr=$3; [ ! $cr ] && cr=med
case $cr in
	none ) zip="-compress=none";;
	min ) zip="--compress=LZX:20";;
	med ) zip="--compress=LZX:50";;
	max ) zip="--solid";;
	* ) echo "Bad Compression Option"; exit 5
esac

echo -e "${CY}Gathering Device Info...$CR"
info=$(lsblk -Po name,fstype,label,size $1)
if [ $(echo "$info" | wc -l) -ne 1 ]; then
	echo "Cannot image whole disk, use partition"; exit 4
fi
type=$(echo $info | sed 's/.*FSTYPE="\([^"]*\).*/\1/')
label=$(echo $info | sed 's/.*LABEL="\([^"]*\).*/\1/')
size=$(echo $info | sed 's/.*SIZE="\([^"]*\).*/\1/')
draw=$(echo $info | sed 's/^NAME="\([^"]*\).*/\1/')
dev=$(dirname $1)/$draw

[ $label ] && n="Name: $label, " || n=""
echo -e "${CM}Create image of $dev (${n}Type: $type, Size: $size) at $img?\n(y/n)$CR"
read -p "> " yn
case $yn in
	yes );;
	y );;
	* ) exit 3
esac

if [ -d /mnt/tmp-disk ]; then
	umount /mnt/tmp-disk || true
fi

# Cleanup for Windows & Linux
unix=""
if [[ $type = ntfs ]]; then
	./ntfs-clean.sh $dev
	echo -e "$CY\n---- Syncing & Ejecting...$CR"
	sync -f /mnt/tmp-disk; sleep 1
	umount /mnt/tmp-disk
elif [[ $type = ext* ]]; then
	./linux-clean.sh $dev
	echo -e "$CY\n---- Syncing...$CR"
	sync -f /mnt/tmp-disk; sleep 1
	unix="--unix-data --config=linux-exclude.ini"
	umount /mnt/tmp-disk
else
	umount $dev || true
fi

echo -e "$CY\n---- Checking $type Disk...$CR"
if [[ $type = ntfs ]]; then ntfsfix -d $dev
elif [[ $type = ext* ]]; then e2fsck -f $dev; fi
sleep 2

echo -e "$CY\n---- Imaging...$CR"
wim="$($label||$draw) $zip --image-property PartType=$type"
echo "CMD: wimcapture /mnt/tmp-disk '$img' $wim $unix" # TEMP
if [[ $type = ntfs ]]; then
	wimcapture $dev "$img" $wim
else
	mkdir -p /mnt/tmp-disk; mount $dev /mnt/tmp-disk
	wimcapture /mnt/tmp-disk "$img" $wim $unix
	umount /mnt/tmp-disk
fi
rmdir /mnt/tmp-disk
echo Done!