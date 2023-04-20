#!/bin/bash
set -e
CY='\x1b[33m'; CM='\x1b[36m'; CR='\x1b[0m'
[ $EUID -ne 0 ] && echo "Please run as root!" && exit 1
[ $# -ne 3 ] && echo "Usage: $0 <imgfile> <dev> <pc-name>" && exit 1
[[ "$1" != *.wim || ! -f "$1" ]] && echo "Error: Imgfile does not exist" && exit 2
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/scripts"

echo -e "${CY}Gathering Device Info...$CR"
info=$(lsblk -Po name,label,pkname $2)
if [ $(echo "$info" | wc -l) -ne 1 ]; then
	echo "Cannot restore to whole disk, use partition"; exit 5
fi
label=$(echo $info | sed 's/.*LABEL="\([^"]*\).*/\1/')
blk=$(echo $info | sed 's/.*PKNAME="\([^"]*\).*/\1/')
draw=$(echo $info | sed 's/^NAME="\([^"]*\).*/\1/')
dev=$(dirname $1)/$draw
if [ $blk ]; then
	blk=/dev/$blk; did=$((`lsblk -P $blk | grep -on $draw | grep -oP '^\d+'`-1))
else blk=$dev; did=1; fi

echo -e "${CY}Gathering Image Info...$CR"
set +e
info=$(wiminfo "$1" -xml 2>&1)
$? && echo $info && exit 3
set -e
size=$(echo "$info" | sed -n 's/.*<TOTALBYTES>\s*\(.*?\)<\/.*/\1/p' | awk '{print(int($0)/1e+9)" GB"}')
name=$(echo "$info" | sed -n 's/.*<DISPLAYNAME>\s*\(.*?\)<\/.*/\1/p') ||\
name=$(echo "$info" | sed -n 's/.*<NAME>\s*\(.*?\)<\/.*/\1/p')
type=$(echo "$info" | sed -n 's/.*<PartType>\s*\(.*?\)<\/.*/\1/p')
[ ! $type ] && echo "Error: Invalid metadata" && exit 6

[ $name ] && n="Name: $name, " || n=""
[ $label ] && dn=" (Name: $label)" || dn=""
echo "${CM}Restore image $1 (${n}Type: $type, Size: $size) to $dev$dn?$CR"
read -p "> " yn
case $yn in
	yes );;
	y );;
	* ) exit 4
esac

for i in $blk??*; do umount $i || true; done

echo -e "$CY\n---- Restoring Partition Data...$CR"
unix=""
if [[ $type = ntfs ]]; then
	tbl=$(sfdisk $blk --list | sed -n 's/.*Disklabel type:\s*\([^\n+]\)/\1/p')
	if [[ $tbl == gpt ]]; then
		sfdisk $blk --part-type $did EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
	elif [[ $tbl == mbr ]]; then
		sfdisk $blk --part-type $did 7
	else echo "Error: Unknown part table $tbl"; exit 6; fi
	mkfs.$type $dev
	#TODO: Label NTFS filesystem
	#echo -e "y\n" | ntfsresize -f $dev
elif [[ $type = ext* ]]; then
	sfdisk $blk --part-type $did L
	#TODO: Init new Linux filesystem
	mkfs.$type $dev
	[ $label ] && e2label $dev $label
	#e2fsck -f $dev
	#resize2fs $dev
	unix="--unix-data"
else
	echo "Error: Unknown type $type"; exit 7
fi

echo -e "$CY\n---- Restoring Image...$CR"
if [[ $type = ntfs ]]; then
	wimapply "$img" $dev
else
	mkdir -p /mnt/tmp-disk; mount $dev /mnt/tmp-disk
	wimapply "$img" /mnt/tmp-disk $unix
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
echo Done!