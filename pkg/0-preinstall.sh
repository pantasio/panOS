#!/bin/bash

#-------------------------------------------------------
# Declaire Variable
CRYPTROOT=/dev/mapper/cryptroot 
echo "${CRYPTROOT}"




#------------
# make sure another PC can SSH into target
clear
# set root passwork for ssh
echo "SET ROOT ISO PASSWORD"
# echo root:qwe123AAA | chpasswd
passwd root

#enable sshd
systemctl enable sshd
systemctl restart sshd
#-------------------------------------------------------

#----------
clear
echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
pacman -S --noconfirm reflector rsync
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
iso=$(curl -4 ifconfig.co/country-iso)
clear
echo -e "Setting up $iso mirrors for faster downloads"
echo "you are -$iso- mirror. If you okay, ReEnter or you can change!"
read -p "Please ReEnter again or Change to 'SG' or 'JP'  " iso
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

timedatectl set-ntp true
sed -i 's/^#Para/Para/' /etc/pacman.conf


#-------------------------------------------------------
mkdir -p /mnt
clear
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
#-------------------------------------------------------

# # --------
# # Crypt partition 3 before format partition.
# clear
# echo "Crypt Parttion"
# sleep 20

# if [[ ${DISK} =~ "nvme" ]]; then
# # If Crypt
# cryptsetup -y --use-random luksFormat "${DISK}p3"
# #Enter YES with uppercase and passwork
# # Ater that Open the lock-box  
# cryptsetup luksOpen "${DISK}p3" cryptroot
# #Enter passwork, Now you format btrfs and use `/dev/mapper/cryptroot`
# clear
# echo "Crypt is done"
# sleep 20
# else
# cryptsetup -y --use-random luksFormat "${DISK}3"
# cryptsetup luksOpen "${DISK}3" cryptroot
# clear
# echo "Crypt is done"
# sleep 20
# fi


# # If Crypt
# cryptsetup -y --use-random luksFormat "${DISK}p3"    # Didnt work

cryptsetup luksFormat -y -v -s 512 -h sha512 -i 5000 "${DISK}p3"
# #Enter YES with uppercase and passwork
# # Ater that Open the lock-box  
cryptsetup luksOpen "${DISK}p3" cryptroot
# #Enter passwork, Now you format btrfs and use `/dev/mapper/cryptroot`
# clear
# echo "Crypt is done"
# sleep 20
# #Dont ask passwd
# # should we do ti manual
# #-------------------------------------------------------

# VMWARE CANT NOT CRYPT 
# mkfs.fat -F32 /dev/sda2
# mkfs.btrfs /dev/sda3 -f    #bc if you repartition without -f, you fail 



;;
*)
echo "Rebooting in 3 Seconds ..." && sleep 1
echo "Rebooting in 2 Seconds ..." && sleep 1
echo "Rebooting in 1 Second ..." && sleep 1
# reboot now
;;
esac

clear
echo "Done Create partition template"
echo "Now you go next script 0a-crypt.sh"


