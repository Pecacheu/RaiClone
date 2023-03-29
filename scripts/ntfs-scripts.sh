set -e
./ntfs-mount.sh "$1"
echo -e "\n---- Writing Scripts..."
scr=$(<WinRename.bat)
scr=${scr//'#1#'/$(basename "$3")}
echo "${scr//'#2#'/$2}" > "/mnt/tmp-disk/ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/WinRename.bat"