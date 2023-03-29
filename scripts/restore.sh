set -e
[ $EUID -ne 0 ] && echo "Please run as root!" && exit 1
[ $# -ne 3 ] && echo "Usage: $0 <imgfile> <dev> <pc-name>" && exit 1
[ ! -f "$1" ] && echo "Error: Imgfile does not exist" && exit 2
[[ "$1" = *.pcl.xz ]] && zip=1

echo "Gathering Device Info..."
info=$(lsblk -Po name,label,pkname $2)
label=$(echo $info | sed 's/.*LABEL="\([^"]*\).*/\1/')
blk=$(echo $info | sed 's/.*PKNAME="\([^"]*\).*/\1/')
draw=$(echo $info | sed 's/^NAME="\([^"]*\).*/\1/')
dev=$(dirname $1)/$draw
if [ $blk ]; then
	blk=/dev/$blk
	did=$((`lsblk -P $blk | grep -on $draw | grep -oP '^\d+'`-1))
else blk=$dev; did=1; fi

echo "Gathering Image Info..."
set +e
if [ $zip ]; then
	info=$(xz -dc "$1" | partclone.info -s - -L /dev/null 2>&1)
else
	info=$(partclone.info -s "$1" -L /dev/null 2>&1)
fi
(echo "$info" | grep -q fail) && echo $info && exit 3
set -e
type=$(echo "$info" | sed -n 's/.*File system:\s*\([^\n]*\).*/\1/p' | awk '{print tolower($0)}')
size=$(echo "$info" | sed -n 's/.*Space in use:\s*\([^\n]*\) =.*/\1/p')

echo "Restore image $1 (Type: $type, Size: $size) to $dev (Name: $label)?"
read -p "> " yn
case $yn in
	yes );;
	y );;
	* ) exit 4
esac

for i in $blk??*; do umount $i || true; done

if [ $zip ]; then
	xz -dcT `nproc` "$1" | partclone.$type -rN -o $dev -L ../restore.log
else
	partclone.$type -rN -s "$1" -o $dev -L ../restore.log
fi

echo -e "\n---- Reversing Disk Shrink..."
if [[ $type = ntfs ]]; then
	tbl=$(sfdisk $blk --list | sed -n 's/.*Disklabel type:\s*\([^\n+]\)/\1/p')
	if [[ $tbl == gpt ]]; then
		sfdisk $blk --part-type $did EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
	elif [[ $tbl == mbr ]]; then
		sfdisk $blk --part-type $did 7
	else echo "Error: Unknown part table $tbl"; exit; fi
	echo -e "y\n" | ntfsresize -f $dev
elif [[ $type = ext* ]]; then
	sfdisk $blk --part-type $did L
	e2fsck -f $dev; resize2fs $dev
else
	echo "Warning: Unknown type $type"
fi

# For Windows NTFS restore only
if [[ $type = ntfs ]]; then
	./ntfs-scripts.sh $dev $3 "$1" || true
	echo -e "\n---- Syncing & Ejecting..."
	sync -f /mnt/tmp-disk; sleep 1
	umount /mnt/tmp-disk
	rmdir /mnt/tmp-disk
fi
echo "Done!"