#!/usr/bin/env bash
# Can boot into Archsystem 
# Create user and copy this script
# Make sure You can connect to internet `wifi-menu` or `nmtui-connect` or `nmtui` 
# 
# Testing 1 in VMware 
# install in empty disk
# Disk Format only 2 partitions: UEFISYS and ROOT
# format disk BTRFS no crypt

# TEST 2 IN REAL MACHINE
# Dual boot with Win10
#Disk format 4 partitions: 
# format disk BTRFS no crypt


# set root passwork for ssh
echo "SET ROOT PASSWORD"
# echo root:qwe123AAA | chpasswd
passwd root

#enable sshd
systemctl enable sshd
systemctl restart sshd

echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
pacman -S --noconfirm reflector rsync
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
iso=$(curl -4 ifconfig.co/country-iso)
echo -e "Setting up $iso mirrors for faster downloads"
echo "you are $iso mirror. If you okay, ReEnter or you can change!"
read -p "Please ReEnter again or Change to 'SG' or 'JP'" iso
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

timedatectl set-ntp true
sed -i 's/^#Para/Para/' /etc/pacman.conf
echo "-------------------------------------------------"
echo -e "-Setting up $iso mirrors for faster downloads"
echo "-------------------------------------------------"
mkdir -p /mnt

echo "-------------------------------------------------"
echo "-------select your disk to format----------------"
echo "-------------------------------------------------"
lsblk
echo "Please enter disk to work on: (example /dev/sda)"
read DISK
echo "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"
read -p "are you sure you want to continue (Y/N):" formatdisk
case $formatdisk in

y|Y|yes|Yes|YES)
echo "--------------------------------------"
echo -e "\nFormatting disk...\n$HR"
echo "--------------------------------------"



########################################
# TEST 1 IN VMWARE begin
########################################
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
sgdisk -t 1:ef02 ${DISK}
sgdisk -t 2:ef00 ${DISK}
sgdisk -t 3:8300 ${DISK}

# label partitions
sgdisk -c 1:"BIOSBOOT" ${DISK}
sgdisk -c 2:"UEFISYS" ${DISK}
sgdisk -c 3:"ROOT" ${DISK}

# make filesystems
echo -e "\nCreating Filesystems...\n$HR"
if [[ ${DISK} =~ "nvme" ]]; then
mkfs.vfat -F32 -n "UEFISYS" "${DISK}p2"
# If Crypt
#cryptsetup -y --use-randome luksFormat "${DISK}p2"
#Enter YES and passwork
# Ater that Open
#cryptsetup luksOpen "${DISK}p2" cryptroot
#Enter passwork, Now you format btrfs and use `/dev/mapper/cryptroot`
mkfs.btrfs -L "ROOT" "${DISK}p3" -f
mount -t btrfs "${DISK}p3" /mnt
else
mkfs.vfat -F32 -n "UEFISYS" "${DISK}2"
mkfs.btrfs -L "ROOT" "${DISK}3" -f
mount -t btrfs "${DISK}3" /mnt
fi
ls /mnt | xargs btrfs subvolume delete
btrfs subvolume create /mnt/@
umount /mnt
;;
*)
echo "Rebooting in 3 Seconds ..." && sleep 1
echo "Rebooting in 2 Seconds ..." && sleep 1
echo "Rebooting in 1 Second ..." && sleep 1
reboot now
;;
esac

# mount target
mount -t btrfs -o subvol=@ -L ROOT /mnt
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount -t vfat -L UEFISYS /mnt/boot/

if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi

echo "--------------------------------------"
echo "-- Arch Install on Main Drive       --"
echo "--------------------------------------"
pacstrap /mnt base base-devel linux linux-firmware git vim grub amd-ucode openssh --noconfirm --needed
pacstrap /mnt efibootmgr sudo archlinux-keyring wget libnewt networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools reflector base-devel linux-headers --noconfirm --needed

genfstab -U /mnt >> /mnt/etc/fstab
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

echo "--------------------------------------"
echo "-- Check for low memory systems <8G --"
echo "--------------------------------------"
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -lt 8000000 ]]; then
    #Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
    mkdir /mnt/opt/swap #make a dir that we can apply NOCOW to to make it btrfs-friendly.
    chattr +C /mnt/opt/swap #apply NOCOW, btrfs needs that.
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile #set permissions.
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    #The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the sysytem itself.
    echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab #Add swap to fstab, so it KEEPS working after installation.
fi

echo "--------------------------------------"
echo "--   SYSTEM READY FOR 0-setup       --"
echo "--------------------------------------"

echo "Now you can run `reboot now`"
echo "to check your system can boot and next installer srcipt"

########################################
# TEST 1 IN VMWARE end
########################################
