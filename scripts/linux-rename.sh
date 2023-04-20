#!/bin/bash
onErr() {
	echo "Oh no, script failed! :("; read
}
set -e
trap 'onErr' ERR
FN=$(readlink -f "${BASH_SOURCE[0]}")
if [ $1 -ne 1 ]; then
	gnome-terminal -c "$FN 1"; exit
fi
echo Sucessfully restored from #1#
echo Renaming this PC to #2#...
sudo hostnamectl set-hostname "#2#"
echo Please reboot to apply changes.
read
rm $FN
sudo reboot