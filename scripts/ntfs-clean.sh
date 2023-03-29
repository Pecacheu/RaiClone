set -e
./ntfs-mount.sh "$1"
echo -e "\n---- Cleaning Windows Junk..."
cd /mnt/tmp-disk
rm -r '$Recycle.Bin' Recovery DumpStack.log.tmp hiberfil.sys pagefile.sys swapfile.sys Windows/*.log Windows/*log.txt lbr MSOCache Recovery 'System Volume Information' 2>/dev/null || true
for d in /mnt/tmp-disk/Users/*/; do
	[ -L "${d%/}" ] && continue # Ignore links
	usr=$(basename "$d"); echo "-- Clean User $usr"
	cd "$d/AppData" 2>/dev/null
	if [[ $usr == "Default" ]]; then
		rm -r ./* 2>/dev/null || true
	else
		rm -r LocalLow Local/Temp Local/Microsoft/Windows/INetCache/* Local/Microsoft/Windows/History/* Local/IconCache.db Local/AMD Local/ATI Roaming/ATI Local/NVIDIA Roaming/NVIDIA Local/Intel Local/OneDrive Local/CEF Local/CrashDumps Local/D3DSCache Local/fontconfig 'Local/Microsoft/Internet Explorer' Local/ConnectedDevicesPlatform Local/cache Local/recently-used.xbel 2>/dev/null || true
	fi
done