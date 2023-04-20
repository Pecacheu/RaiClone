# RaiClone
Easy Disk Image Backup & Restore /w Compression & Cloud Support, Linux & Windows Support (In a Linux recovery environment.)

## Usage

Replace the following in `RaiDownloader.sh` with appropriate settings. This is the only file that needs to be bundled in the recovery environment, it will perform all setup automatically.
```bash
srv="SERVER_ADDRESS_HERE"
mnt="MOUNTPOINT_HERE"
pwd="PASSWORD_HERE"
```

Before running clone and restore scripts, run `init.sh` first.

More info coming soon.

## TODO

- Interactive selector menu (using dialog package?) to choose the disk to image, more user friendly.
- Detect if running on a text-only terminal and DON'T kill & relaunch the terminal process to get fullscreen.