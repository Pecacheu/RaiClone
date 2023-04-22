#!/bin/bash
set -e
CY='\x1b[33m'; CM='\x1b[36m'; CR='\x1b[0m'
[ $EUID -ne 0 ] && echo "Please run as root!" && exit 1
[ $# -ne 3 ] && echo "Usage: $0 <imgfile> <dev> <pc-name>" && exit 1
[[ "$1" != *.wim || ! -f "$1" ]] && echo "Error: Imgfile does not exist" && exit 2
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/scripts"

echo -e "${CY}Gathering Device Info...$CR"
info=$(lsblk -Po name,label,pkname,size $2)
if [ $(echo "$info" | wc -l) -ne 1 ]; then
	echo "Cannot restore to whole disk, use partition"; exit 5
fi
label=$(echo $info | sed 's/.*LABEL="\([^"]*\).*/\1/')
blk=$(echo $info | sed 's/.*PKNAME="\([^"]*\).*/\1/')
draw=$(echo $info | sed 's/^NAME="\([^"]*\).*/\1/')
dSize=$(echo $info | sed 's/.*SIZE="\([^"]*\).*/\1/')
dev=$(dirname $2)/$draw
if [ $blk ]; then
	blk=/dev/$blk; did=$((`lsblk -P $blk | grep -on $draw | grep -oP '^\d+'`-1))
else blk=$dev; did=1; fi

echo -e "${CY}Gathering Image Info...$CR"
set +e
info=$(wiminfo "$1" -xml 2>&1 | tr -d '\0\200-\377')
[ $? -ne 0 ] && echo $info && exit 3
set -e
size=$(echo $info | sed -n 's/.*<TOTALBYTES>\s*\([^<]*\)<\/.*/\1/p' | awk '{print(int($0)/1e+9)" GB"}')
name=$(echo $info | sed -n 's/.*<DISPLAYNAME>\s*\([^<]*\)<\/.*/\1/p') ||\
name=$(echo $info | sed -n 's/.*<NAME>\s*\([^<]*\)<\/.*/\1/p')
type=$(echo $info | sed -n 's/.*<PartType>\s*\([^<]*\)<\/.*/\1/p')
[ ! $type ] && echo "Error: Invalid metadata" && exit 6

[ "$name" ] && n="Name: $name, " || n=""
[ "$label" ] && dn="Name: $label, " || dn=""
echo -e "${CM}Restore image $1 (${n}Type: $type, Size: $size) to $dev (${dn}Size: $dSize)?$CR"
read -p "> " yn
case $yn in
	yes );;
	y );;
	* ) exit 4
esac

for i in $blk??*; do umount $i || true; done
systemctl disable --now systemd-oomd

echo -e "$CY\n---- Restoring Partition Data...$CR"
unix=""
if [[ $type = ntfs ]]; then
	tbl=$(sfdisk $blk --list | sed -n 's/.*Disklabel type:\s*\([^\n+]\)/\1/p')
	if [[ $tbl == gpt ]]; then
		sfdisk $blk --part-type $did EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
	elif [[ $tbl == dos ]]; then
		sfdisk $blk --part-type $did 7
	else echo "Error: Unknown part table $tbl"; exit 6; fi
	mkntfs -QvL "$label" $dev
elif [[ $type = ext* ]]; then
	sfdisk $blk --part-type $did L
	mkfs.$type -E lazy_itable_init $dev
	[ "$label" ] && e2label $dev "$label"
	unix="--unix-data"
else
	echo "Error: Unknown type $type"; exit 7
fi

sleep 2
echo -e "$CY\n---- Checking $type Disk...$CR"
if [[ $type = ntfs ]]; then ntfsfix -d $dev
elif [[ $type = ext* ]]; then e2fsck -f $dev; fi

echo -e "$CY\n---- Restoring Image...$CR"
if [[ $type = ntfs ]]; then
	wimapply "$1" $dev
else
	mkdir -p /mnt/tmp-disk; mount $dev /mnt/tmp-disk
	wimapply "$1" /mnt/tmp-disk $unix
fi

# Windows & Linux Restore Scripts
echo -e "$CY\n---- Writing Scripts...$CR"
if [[ $type = ntfs ]]; then
	./ntfs-mount.sh $dev
	scr=$(<WinRename.bat); scr=${scr//'#1#'/$(basename "$1")}
	echo "${scr//'#2#'/$3}" > "/mnt/tmp-disk/ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/WinRename.bat"
elif [[ $type = ext* ]]; then
	scr=$(<linux-rename.sh); scr=${scr//'#1#'/$(basename "$1")}
	dst=/mnt/tmp-disk/etc/profile.d/temp-rename.sh
	echo "${scr//'#2#'/$3}" > $dst; chmod +x $dst
fi
echo -e "$CY\n---- Syncing & Ejecting...$CR"
sync -f /mnt/tmp-disk; sleep 1
umount /mnt/tmp-disk; rmdir /mnt/tmp-disk
systemctl enable systemd-oomd
echo Done!