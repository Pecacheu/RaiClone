dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
dst=~/Desktop/RaiClone/
ro="-aP --no-perms --no-group --del"
if [[ "$dir/" != $dst ]]; then
	echo "Sync from USB..."
	rsync $ro "$dir/" $dst
	gnome-terminal --maximize -- bash $dst/init.sh
elif [[ $1 = cloud ]]; then
	echo "Sync from Cloud..."
	$dst/scripts/setup.sh
	rsync $ro "/mnt/share/RaiClone/" $dst
else
	echo "Sync to USB..."
	if [[ $1 != nolog ]]; then
		sudo rm $dir/*.log 2>/dev/null
	elif [ -d "$1" ]; then
		echo "-- Sync to $1"; rsync $ro $dir "$1/"
	fi
	shopt -s nullglob
	for d in /media/$USER/UBUNTU*/; do
		echo "-- Sync to $d"; rsync $ro $dir "$d"
	done
	if [ -d /mnt/share/RaiClone ]; then
		echo "-- Sync to Cloud"; rsync $ro $dir /mnt/share/
	fi
	sync
fi