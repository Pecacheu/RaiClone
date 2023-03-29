while ! $(ping google.com -c 1 > /dev/null); do
	echo Waiting for internet...; sleep 5
done

chmod +x ./*.sh
dpkg -s partclone | grep -q "Status: install ok"
n=$?
set -e
if [ $n -ne 0 ]; then
sudo sed -i 's/^\(deb cdrom:.*\)$/# \1/' /etc/apt/sources.list
sudo apt-add-repository -y universe
sudo apt -y install partclone sshfs ssh #autoconf gcc make libtool libz-dev libbz2-dev liblzo2-dev liblz4-dev

#echo "---- Building lrzip..."
#wget https://github.com/ckolivas/lrzip/archive/refs/tags/v0.651.tar.gz -O lrzip.tar.gz
#tar -xf lrzip.*; rm lrzip.*
#cd lrzip-*
#./autogen.sh
#make -j `nproc`
#sudo make install
#cd ..; rm -r lrzip-*

#echo "---- Building partclone-utils..."
#wget https://downloads.sourceforge.net/project/partclone-utils/partclone-utils-0.4.3.tar.gz
#tar -xf partclone-*; rm partclone-*.tar.gz
#cd partclone-*
#autoreconf -i
#./configure
#make -j `nproc`
#sudo make install
#cd ..; rm -r partclone-*
fi

srv=$(<srv); mnt=$(<mnt); pwd=$(<srv-pwd)
addr=$(echo $srv | grep -Eo '[^@]+' | tail -1)

echo ---- Connecting to $addr...
sudo pkill sshfs -KILL || true
sudo fusermount -u /mnt/share || true
sudo sh -c "mkdir -p /mnt/share ~/.ssh; ssh-keyscan $addr > ~/.ssh/known_hosts"
echo $pwd | sudo sshfs -o allow_other,reconnect,password_stdin,ServerAliveInterval=10,auto_unmount $srv:$mnt /mnt/share