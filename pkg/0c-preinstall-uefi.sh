#!/usr/bin/env bash
####################
# Ask some info
clear
echo "        -------------------------------------------------"
echo "        -------select your WIN10 EFI boot----------------"
echo "        -------------------------------------------------"
lsblk
# -s for secrect input this flat for password
# read -s -p "        Please enter WIN10 boot partition to work on: (example /dev/nvme0n1p3)  " WINEFI
read -p "        Please enter WIN10 boot partition to work on: (example /dev/nvme0n1p3)  " WINEFI

clear
echo "        -------------------------------------------------"
echo "        -------select your disk to install system--------"
echo "        -------------------------------------------------"
lsblk
echo ""
echo ""
# echo "        Please enter disk to work on: (example /dev/nvme1n1)"
# enter twice partition 
# read -p "Disk: " DISK
while true; do
  echo "select your disk to install: "
  echo "If you have NVME, you can enter:   /dev/nvme1n1"
  echo "If you have SATA, you can enter:   /dev/sda"
  read -p "Your chose is:  " DISK
  echo
  read -p "Repeat to make sure you doing right: " DISK2
  echo
  [ "$DISK" = "$DISK2" ] && break
  echo " Your enter is wrong. Please try again"
done
echo "Thank you for your infomation"
sleep 5
###DONE

# If Crypt
# cryptsetup -y --use-random luksFormat "${DISK}p3"
#Enter YES with uppercase and passwork
# Ater that Open the lock-box  
# cryptsetup luksOpen "${DISK}p3" cryptroot
#Enter passwork, Now you format btrfs and use `/dev/mapper/cryptroot`

################
#set label for partition again
# label partitions
sgdisk -c 1:"BIOSBOOT" ${DISK}
sgdisk -c 2:"UEFISYS" ${DISK}
sgdisk -c 3:"ROOT" ${DISK}
###DONE








################
# mount target
if [[ ${DISK} =~ "nvme" ]]; then
mount -t vfat -L "UEFISYS" /mnt/boot/

mount ${DISK}p3 /mnt
cd /mnt
mkdir -p /mnt/{boot,home,var,srv,opt,tmp,swap,.snapshots}
btrfs subvolume create @root
btrfs subvolume create @home
btrfs subvolume create @srv
btrfs subvolume create @tmp
btrfs subvolume create @opt
btrfs subvolume create @.snapshots
umount /mnt

mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@root ${DISK}p3 /mnt/
mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@home ${DISK}p3 /mnt/home
mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@srv ${DISK}p3 /mnt/srv
mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@tmp ${DISK}p3 /mnt/tmp
mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@opt ${DISK}p3 /mnt/opt
mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@.snapshots ${DISK}p3 /mnt/.snapshots
mount -o nodatacow,subvol=@swap ${DISK}p3 /mnt/swap
mount -o nodatacow,subvol=@var ${DISK}p3 /mnt/var

else

mount -t vfat -L "UEFISYS" /mnt/boot/
mount ${DISK}3 /mnt
cd /mnt
mkdir -p /mnt/{boot,home,var,srv,opt,tmp,swap,.snapshots}
btrfs subvolume create @root
btrfs subvolume create @home
btrfs subvolume create @srv
btrfs subvolume create @tmp
btrfs subvolume create @opt
btrfs subvolume create @.snapshots
umount /mnt
# discard=async
mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@root ${DISK}3 /mnt
mkdir -p /mnt/{boot,home,var,srv,opt,tmp,swap,.snapshots}
mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@home ${DISK}3 /mnt/home
mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@srv ${DISK}3 /mnt/srv
mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@tmp ${DISK}3 /mnt/tmp
mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@opt ${DISK}3 /mnt/opt
mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@.snapshots ${DISK}3 /mnt/.snapshots
mount -o nodatacow,subvol=@swap ${DISK}3 /mnt/swap
mount -o nodatacow,subvol=@var ${DISK}3 /mnt/var
fi

# Mount Win10 EFI partition to /mnt/boot/efi
mkdir -p /mnt/boot/efi
mount "${WINEFI}" /mnt/boot/efi


# Check mount 
if ! grep -qs '/mnt' /proc/mounts; then
    echo " /mnt dont mount"
    sleep 5
    echo "Drive is not mounted can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi

echo "--------------------------------------"
echo "-- Arch Install on Main Drive       --"
echo "--------------------------------------"

pacstrap /mnt base base-devel linux-lts linux-lts-headers linux-firmware git neovim grub grub-btrfs openssh btrfs-progs --needed

pacstrap /mnt efibootmgr sudo archlinux-keyring wget libnewt networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools reflector --needed

#
# determine processor type and install microcode
# 
proc_type=$(lscpu | awk '/Vendor ID:/ {print $3}')
case "$proc_type" in
	GenuineIntel)
		print "Installing Intel microcode"
		pacstrap /mnt intel-ucode
		proc_ucode=intel-ucode.img
		;;
	AuthenticAMD)
		print "Installing AMD microcode"
		pacstrap /mnt amd-ucode
		proc_ucode=amd-ucode.img
		;;
esac	


# Graphics Drivers find and install
if lspci | grep -E "NVIDIA|GeForce"; then
    pacstrap /mnt nvidia nvidia-xconfig 	
    echo "NVIDIA"
elif lspci | grep -E "Radeon"; then
    pacstrap /mnt xf86-video-amdgpu 
    echo "AMD"
elif lspci | grep -E "Integrated Graphics Controller"; then
    pacstrap /mnt libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils 
    echo "Intel GPU"
elif lspci | grep -E "VMware SVGA II Adapter"; then
    echo "VMware"
fi

genfstab -U /mnt >> /mnt/etc/fstab
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# echo "--------------------------------------"
# echo "-- Check for low memory systems <8G --"
# echo "--------------------------------------"
# TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
# if [[  $TOTALMEM -lt 8000000 ]]; then
#     #Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
#     mkdir /mnt/opt/swap #make a dir that we can apply NOCOW to to make it btrfs-friendly.
#     chattr +C /mnt/opt/swap #apply NOCOW, btrfs needs that.
#     dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
#     chmod 600 /mnt/opt/swap/swapfile #set permissions.
#     chown root /mnt/opt/swap/swapfile
#     mkswap /mnt/opt/swap/swapfile
#     swapon /mnt/opt/swap/swapfile
#     #The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the sysytem itself.
#     echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab #Add swap to fstab, so it KEEPS working after installation.
# fi
clear
echo "--------------------------------------"
echo "--   SYSTEM READY FOR 0-setup       --"
echo "--------------------------------------"
echo "Now you moving on Next Step!!!"

# Copy script in
cp /root/panOS /mnt/tmp/panOS

# CHECK AGAIN THIS STEP IS DONE
echo "### Now you check this step is DONE with some command below"
echo "         cat /mnt/etc/fstab"
echo "         ls /mnt/tmp/panOS"
echo "         cat /mnt/etc/pacman.d/mirrorlist"
echo "         ls /dev/mapper/"

echo "### In the First time you can going to Arch new system."
echo "    Run arch-chroot before go next step"
echo "    Now my location script is /tmp/panOS"
echo "    go next step >>"
arch-chroot /mnt
