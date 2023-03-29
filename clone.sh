fn="Carbon-$(date +%b-%Y)"
file="/mnt/share/$fn"
dev=/dev/nvme0n1p1

cd scripts
sudo ./clone.sh $dev $file