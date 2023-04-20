CY='\x1b[33m'; CR='\x1b[0m'
echo -e "$CY\n---- Repairing & Mounting NTFS...$CR"
umount $1
ntfsfix -d $1 2>/dev/null
set -e
mkdir -p /mnt/tmp-disk
ntfs-3g -o remove_hiberfile $1 /mnt/tmp-disk