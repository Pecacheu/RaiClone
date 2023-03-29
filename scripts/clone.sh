set -e
[ $EUID -ne 0 ] && echo "Please run as root!" && exit 1
[[ $# < 2 ]] && echo "Usage: $0 <dev> <imgfile> [zip=yes]" && exit 1
ext=".pcl"
[[ $3 != nozip ]] && ext=".pcl.xz"
name="$2$ext"
[[ "$2" = *$ext ]] && name="$2"
[ -e "$name" ] && echo "Error: File exists" && exit 2

out="tee /dev/null"
if [[ $3 != nozip ]]; then
	mem=$(lsmem | sed -n 's/.*Total online memory:\s*\([^\n]*\).*/\1/p')
	muse=$(awk -vn=$mem 'BEGIN{print(int(n*.75))}')G
	echo "Detected $mem RAM; Using $muse for compression."
	out="xz -z9ecT `nproc` -M $muse"
fi

echo "Gathering Device Info..."
info=$(lsblk -Po name,fstype,label,pkname,log-sec $1)
type=$(echo $info | sed 's/.*FSTYPE="\([^"]*\).*/\1/')
label=$(echo $info | sed 's/.*LABEL="\([^"]*\).*/\1/')
sec=$(echo $info | sed 's/.*LOG-SEC="\([^"]*\).*/\1/')
blk=$(echo $info | sed 's/.*PKNAME="\([^"]*\).*/\1/')
draw=$(echo $info | sed 's/^NAME="\([^"]*\).*/\1/')
dev=$(dirname $1)/$draw
if [ $blk ]; then
	bdev=1; blk=/dev/$blk
	did=$((`lsblk -P $blk | grep -on $draw | grep -oP '^\d+'`-1))
	echo "Gathering Partition Info..."
	info=$(parted $blk unit s print)
	ptot=$(echo "$info" | sed -n "s|^\s*Disk $blk: \([0-9]\+\).*|\1|p")
	pst=$(echo "$info" | sed -n "s|^\s*$did\s\+\([0-9]\+\).*|\1|p")
	pnxt=$(echo "$info" | sed -n "s|^\s*$(($did+1))\s\+\([0-9]\+\).*|\1|p")
	ptt=$(echo "$info" | sed -n 's|^\s*Partition Table: \([a-z]\+\).*|\1|p')
	[ $pnxt ] || pnxt=$ptot # Default to fill
fi

echo -e "Create image of $dev (Name: $label, Type: $type) at $name?\n(y/n or 'fix')"
read -p "> " yn
case $yn in
	yes );;
	y );;
	fix ) fix=1;;
	* ) exit 3
esac

resize() {
	parted $blk resizepart $did $1s
}

if [[ $fix != 1 ]]; then
	# Cleanup for Windows NTFS
	if [[ $type = ntfs ]]; then
		./ntfs-clean.sh $dev
		echo -e "\n---- Syncing & Ejecting..."
		sync -f /mnt/tmp-disk; sleep 1
		umount /mnt/tmp-disk
		rmdir /mnt/tmp-disk
	else
		umount $dev || true
	fi

	echo -e "\n---- Shrinking $type Disk..."
	if [ $bdev ]; then
		if [[ $type = ntfs ]]; then
			if info=$(ntfsresize -fi $dev); then
				nsize=$(echo $info | sed -n 's/.*You might resize at \([0-9]*\).*/\1/p')
				prt=$(($pst+(($nsize/$sec-1)/2048+1)*2048))
				echo -e "\n-- Resize: $nsize, Sectors: $pst to $prt"
				echo -e "y\n" | ntfsresize -fs $nsize $dev
				resize $prt
			fi
		elif [[ $type = ext* ]]; then
			e2fsck -f $dev; resize2fs -M $dev
			info=$(dumpe2fs -h $dev)
			bcnt=$(echo $info | sed -n 's/.*Block count:\s*\([0-9]*\).*/\1/p')
			bsize=$(echo $info | sed -n 's/.*Block size:\s*\([0-9]*\).*/\1/p')
			prt=$(($pst+(($bcnt*$bsize/$sec-1)/2048+1)*2048))
			echo -e "\n-- Resize: $bcnt*$bsize/$sec, Sectors: $pst to $prt"
			resize $prt
		else
			echo "Error: Unknown type!"; exit 4
		fi
	else
		echo "Warning: Cannot shrink virtual disk."
	fi
	if [[ $type = ntfs ]]; then ntfsfix -d $dev
	elif [[ $type = ext* ]]; then e2fsck -f $dev; fi
	sleep 2

	partclone.$type -c -s $dev -x "$out" -o "'$name'" -L ../clone.log
fi

if [ $bdev ]; then
	echo -e "\n---- Reversing Disk Shrink..."
	[[ $ptt = gpt ]] && pnew=$(($pnxt-34)) || pnew=$(($pnxt-1))
	if [[ $type = ntfs ]]; then
		resize $pnew; echo -e "y\n" | ntfsresize -f $dev
	elif [[ $type = ext* ]]; then
		resize $pnew; e2fsck -f $dev; resize2fs $dev
	fi
fi
echo "Done!"