fn="Carbon-Jan-2023.pcl.xz"
file="/mnt/share/$fn"
dev=/dev/nvme0n1p1

if [[ $# != 1 ]]; then
	echo "Usage: $0 <pc-name>"; exit 1
fi
cd scripts
sudo ./restore.sh $file $dev $1