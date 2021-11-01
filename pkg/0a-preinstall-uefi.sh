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
echo "        -------select your disk to format----------------"
echo "        -------------------------------------------------"
lsblk
echo ""
echo ""
# echo "        Please enter disk to work on: (example /dev/nvme1n1)"
# enter twice partition 
# read -p "Disk: " DISK
while true; do
  read -p "select your disk to format: (example /dev/nvme1n1)  " DISK
  echo
  read -p "select your disk to format: (example /dev/nvme1n1) (again): " DISK2
  echo
  [ "$DISK" = "$DISK2" ] && break
  echo " Your enter is wrong. Please try again"
done
echo "Thank you for your infomation"
###DONE


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

clear
echo "Now you Encript partition with Luks by manual"
echo
cat ./pkg/crypt-partition.txt
sleep 5

cryptsetup -y --use-random luksFormat "${DISK}p3"
cryptsetup luksOpen "${DISK}p3" cryptroot

mkfs.btrfs -L "ROOT" -f
mount -t btrfs -L "ROOT" /mnt
else
mkfs.vfat -F32 -n "UEFISYS"
mkfs.btrfs -L "ROOT" -f
mount -t btrfs -L "ROOT" /mnt
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