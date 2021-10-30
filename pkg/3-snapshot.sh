#after login to user
sudo umount /.snapshots
sudo rm -r /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo mount -a 
sudo chmod 750 /.snapshots
sudo vim /etc/snapper/configs/root

# edit
#ALLOW_USER="bungbu"

# and 
# TIMELINE_MIN_AGE 1800-5-7-0-0-0

sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer

# Install yay
git clone https://aur.archlinux.org/yay
cd yay
makepkg -si PKGBUILD
cd 

yay -S snap-pac-grub snapper-gui


sudo mkdir -p /etc/pacman.d/hooks
sudo vim /etc/pacman.d/hooks/50-bootbackup.hook
# add
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove 
Type = Path 
Target = boot/*

[Action]
Depends = rsync
Description = Backing up /boot....
When = PreTransaction
Exec = /ustr/bin/rsync -a --delete /boot /.bootbackup

sudo vim /etc/default/ grub

# add video=11920x1080
# After edit
sudo grubmkconfig -o /boot/grub/grub.cfg
#fix some permision
sudo chmod a+rx /.snapshots
sudo chonw :bungbu /.snapshots
reboot
