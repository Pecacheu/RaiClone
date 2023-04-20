dev=/dev/nvme0n1p1

if [[ $# != 2 ]]; then
	echo "Usage: $0 <img> <pc-name>"; exit 1
fi
cd scripts
sudo ./restore.sh $1 $dev $2