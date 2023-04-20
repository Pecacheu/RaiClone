fn="$1-$(date +%b-%Y)"
file="/mnt/share/$fn"

if [[ $# != 2 ]]; then
	echo "Usage: $0 <type> <dev>"; exit 1
fi
cd scripts
sudo ./clone.sh $2 $file max