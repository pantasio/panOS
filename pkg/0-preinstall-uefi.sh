#!/usr/bin/env bash
# Can boot into Archsystem 
# Create user and copy this script
# Make sure You can connect to internet `wifi-menu` or `nmtui-connect` or `nmtui` 
# iwctl
# station wlan0 connect oft_5G
# -> enter pass
# ping google.com -c 2

#####
# Old way: You use another PC ssh into target machine
# set root passwork for ssh
# echo "SET ROOT ISO PASSWORD"
# echo root:qwe123AAA | chpasswd
# passwd root
#enable sshd
# systemctl enable sshd
# systemctl restart sshd

echo " I need some config, so need to ask you before"
echo " we run this script."

iso=$(curl -4 ifconfig.co/country-iso)
echo "you are $iso mirror. If you okay, ReEnter or you can change!"
read -p "Please enter again. Change to 'SG' or 'JP'" iso

clear
echo "-------------------------------------------------"
echo "-------select your disk to format----------------"
echo "-------------------------------------------------"
lsblk
echo "Please enter disk to work on: (example /dev/sda)"
read DISK

clear
echo "-------------------------------------------------"
echo "-------select your WIN10 EFI boot----------------"
echo "-------------------------------------------------"
lsblk
echo "Please enter WIN10 boot partition to work on: (example /dev/nvme0n1p2)"
read WINEFI

echo "-------Thank you for your information----------------"




clear
echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
pacman -S --noconfirm reflector rsync
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -e "Setting up $iso mirrors for faster downloads"
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

timedatectl set-ntp true
sed -i 's/^#Para/Para/' /etc/pacman.conf


mkdir -p /mnt
clear
echo " I ask you again to make sure you doing right"
echo " We will format all data on your disk"
echo "-------------------------------------------------"
echo "-------select your disk to format----------------"
echo "-------------------------------------------------"
lsblk
echo "Please enter disk to work on: (example /dev/sda)"
read DISK
sleep 5
# Check 2 time enter your disk 

clear
echo "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"
read -p "are you sure you want to continue (Y/N):" formatdisk
case $formatdisk in

y|Y|yes|Yes|YES)

clear
echo "--------------------------------------"
echo -e "\nFormatting disk...\n$HR"
echo "--------------------------------------"

# because VMware need 32M first partition set BIOS boot
#Make sure Wipe partition table on your Disk
wipefs -a ${DISK}
# disk prep
sgdisk -Z ${DISK} # zap all on disk
#dd if=/dev/zero of=${DISK} bs=1M count=200 conv=fdatasync status=progress
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# create partitions
sgdisk -n 1:0:32M ${DISK} # for VMware have BIOS boot
sgdisk -n 2:0:+512M ${DISK} # partition 1 (UEFI SYS), default start block, 512MB
sgdisk -n 3:0:0     ${DISK} # partition 2 (Root), default start, remaining

# set partition types
sgdisk -t 1:ef02 ${DISK} # Set BIOS file system
sgdisk -t 2:ef00 ${DISK} # EFI file system
sgdisk -t 3:8300 ${DISK} # Linux File system

# label partitions
sgdisk -c 1:"BIOSBOOT" ${DISK}
sgdisk -c 2:"UEFISYS" ${DISK}
sgdisk -c 3:"ROOT" ${DISK}

# make filesystems
echo -e "\nCreating Filesystems...\n$HR"
if [[ ${DISK} =~ "nvme" ]]; then
mkfs.vfat -F32 -n "UEFISYS" "${DISK}p2"

# If Crypt
cryptsetup -y --use-randome luksFormat "${DISK}p3"
#Enter YES with uppercase and passwork
# Ater that Open the lock-box  
cryptsetup luksOpen "${DISK}p3" cryptroot
#Enter passwork, Now you format btrfs and use `/dev/mapper/cryptroot`

mkfs.btrfs -L "ROOT" "${DISK}p3" -f
mount -t btrfs "${DISK}p3" /mnt
else
mkfs.vfat -F32 -n "UEFISYS" "${DISK}2"
mkfs.btrfs -L "ROOT" "${DISK}3" -f
mount -t btrfs "${DISK}3" /mnt
fi

ls /mnt | xargs btrfs subvolume delete
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@srv
btrfs subvolume create /mnt/@opt
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@swap
btrfs subvolume create /mnt/@.snapshots
umount /mnt
;;
*)
echo "Rebooting in 3 Seconds ..." && sleep 1
echo "Rebooting in 2 Seconds ..." && sleep 1
echo "Rebooting in 1 Second ..." && sleep 1
reboot now
;;
esac
# end case

################
# mount target
if [[ ${DISK} =~ "nvme" ]]; then
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@root -L "ROOT" /mnt
echo "mount /mnt is good"
mkdir -p /mnt/{boot,home,var,srv,opt,tmp,swap,.snapshots}
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@home -L "ROOT" /mnt/home
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@srv -L "ROOT" /mnt/srv
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@tmp -L "ROOT" /mnt/tmp
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@opt -L "ROOT" /mnt/opt
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@.snapshots -L "ROOT" /mnt/.snapshots
mount -o nodatacow,subvol=@swap -L "ROOT" /mnt/swap
mount -o nodatacow,subvol=@var -L "ROOT" /mnt/var

mount -t vfat "${DISK}p3" /mnt/boot/
else
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@root -L "ROOT" /mnt
mkdir -p /mnt/{boot,home,var,srv,opt,tmp,swap,.snapshots}
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@home -L "ROOT" /mnt/home
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@srv -L "ROOT" /mnt/srv
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@tmp -L "ROOT" /mnt/tmp
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@opt -L "ROOT" /mnt/opt
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@.snapshots -L "ROOT" /mnt/.snapshots
mount -o nodatacow,subvol=@swap -L "ROOT" /mnt/swap
mount -o nodatacow,subvol=@var -L "ROOT" /mnt/var

mount -t vfat -L "UEFISYS" /mnt/boot/
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

pacstrap /mnt base base-devel linux-lts linux-lts-headers linux-firmware git vim grub openssh btrfs-progs --noconfirm --needed

pacstrap /mnt efibootmgr sudo archlinux-keyring wget libnewt networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools reflector base-devel  --noconfirm --needed

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
