echo -e "\n---- Repairing & Mounting NTFS..."
umount $1
ntfsfix -d $1 2>/dev/null
set -e
mkdir -p /mnt/tmp-disk
ntfs-3g -o remove_hiberfile $1 /mnt/tmp-disk