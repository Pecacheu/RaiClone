#Cloud Sync Settings
srv="SERVER_ADDRESS_HERE"
mnt="MOUNTPOINT_HERE"
pwd="PASSWORD_HERE"

echo RaiClone Downloader v1.2.2
while ! $(ping google.com -c 1 > /dev/null); do
	echo Waiting for internet...; sleep 5
done

dpkg -s sshfs | grep -q "Status: install ok"
n=$?
set -e
if [ $n -ne 0 ]; then
	sudo apt-add-repository -y universe
	sudo apt -y install sshfs git
fi

echo ---- Fetching Latest RaiClone...
git clone https://github.com/Pecacheu/RaiClone ~/Desktop/RaiClone

echo ---- Copying Settings...
if [[ $1 == "local" ]]; then
	cf=$(<$dst/clone.sh)
	echo "${cf//'/mnt/share'/$drv}" > $dst/clone.sh
	rf=$(<$dst/restore.sh)
	echo "${rf//'/mnt/share'/$drv}" > $dst/restore.sh
fi
cd $dst/scripts
echo $srv > srv
echo $mnt > mnt
echo $pwd > srv-pwd

gnome-terminal --maximize -- bash $dst/init.sh
kill -n1 $(ps -ho ppid -p $$)