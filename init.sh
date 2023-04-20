#!/bin/bash
echo "Running Setup..."
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

onErr() {
	echo "Oh no, setup failed! :("; read
}
set -e
trap 'onErr' ERR

#LiveUSB Config
if [ -d /cdrom ]; then
	#Avoid issues with LiveUSB removal
	sudo umount -lf /var/log || true
	sudo umount -lf /cdrom || true
fi

chmod +x ./*.sh
cd scripts
sudo bash ./setup.sh
cd ..
clear
echo Welcome to RaiClone v2.0.3 by Pecacheu. Use \'./clone.sh\' or \'./restore.sh\'
set +e
bash