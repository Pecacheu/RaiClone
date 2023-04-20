#!/bin/bash
#Cloud Sync Settings
srv="SERVER_ADDRESS_HERE"
mnt="MOUNTPOINT_HERE"
pwd="PASSWORD_HERE"

echo RaiClone Downloader v1.2.3
while ! $(ping google.com -c 1 > /dev/null); do
	echo Waiting for internet...; sleep 5
done

dpkg -s git | grep -q "Status: install ok"
n=$?
set -e
if [ $n -ne 0 ]; then
	sudo apt-add-repository -y universe
	sudo apt -y install git
fi

echo ---- Fetching Latest RaiClone...
dst=$(readlink -f ~/Desktop/RaiClone)
if [ -d $dst ]; then cd $dst; git pull
else git clone https://github.com/Pecacheu/RaiClone $dst; fi

echo ---- Copying Settings...
cd $dst/scripts
echo $srv > srv
echo $mnt > mnt
echo $pwd > srv-pwd

gnome-terminal --maximize -- bash $dst/init.sh
kill -n1 $(ps -ho ppid -p $$)