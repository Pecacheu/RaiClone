set -e
if [[ $# != 1 || ! "$1" = *.pcl ]]; then
	echo "Usage: $0 <imgfile>"; exit 1
fi
if [[ ! -f "$1" ]]; then
	echo "Error: Imgfile does not exist"; exit 2
fi

name=$(basename -s .pcl "$1")
echo "Mounting image $name"
sudo modprobe nbd
sudo imagemount -v 3 -Dr -d /dev/nbd1 -f "$1" -m "/media/$USER/$name"