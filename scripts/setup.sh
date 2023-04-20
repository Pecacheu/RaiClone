while ! $(ping google.com -c 1 > /dev/null); do
	echo Waiting for internet...; sleep 5
done

chmod +x ./*.sh
dpkg -s wimtools | grep -q "Status: install ok"
n=$?
set -e
if [ $n -ne 0 ]; then
sed -i 's/^\(deb cdrom:.*\)$/# \1/' /etc/apt/sources.list
apt-add-repository -y universe
apt -y install wimtools sshfs ssh gawk
fi

srv=$(<srv); mnt=$(<mnt); pwd=$(<srv-pwd)
addr=$(echo $srv | gawk 'match($0, /^([A-Za-z0-9]+)@([A-Za-z0-9.]+)(:([0-9]+))?/, a) {print (a[4]?"-p "a[4]" ":"")a[2]}')
srv=$(echo $srv | gawk 'match($0, /^([A-Za-z0-9]+)@([A-Za-z0-9.]+)(:([0-9]+))?/, a) {print (a[4]?"-p "a[4]" ":"")a[1]"@"a[2]}')

echo ---- Connecting to $addr...
pkill sshfs -KILL || true
fusermount -u /mnt/share || true
sh -c "mkdir -p /mnt/share ~/.ssh; ssh-keyscan $addr > ~/.ssh/known_hosts"
echo $pwd | sshfs -o allow_other,reconnect,password_stdin,ServerAliveInterval=10,auto_unmount $srv:$mnt /mnt/share