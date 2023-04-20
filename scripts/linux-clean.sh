set -e
CY='\x1b[33m'; CR='\x1b[0m'
echo -e "$CY\n---- Mounting...$CR"
mkdir -p /mnt/tmp-disk
mount $1 /mnt/tmp-disk
echo -e "$CY\n---- Cleaning Linux Junk...$CR"
cd /mnt/tmp-disk
rm -r tmp media/* mnt/* var/log 2>/dev/null || true
for d in /mnt/tmp-disk/home/*/; do
	[ -L "${d%/}" ] && continue # Ignore links
	usr=$(basename "$d"); echo "-- Clean User $usr"
	cd "$d"
	rm -r .nv .cache .bash_history .local/share/Trash 2>/dev/null || true
done