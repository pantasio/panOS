#1/bin/bash


#-----------
# make filesystems
echo -e "\nCreating Filesystems...\n$HR"
if [[ ${DISK} =~ "nvme" ]]; then
mkfs.vfat -F32 -n "UEFISYS" "${DISK}p2"



mkfs.btrfs -L "ROOT" "${DISK}p3" -f
mount -t btrfs "${DISK}p3" /mnt
else
mkfs.vfat -F32 -n "UEFISYS" "${DISK}2"
mkfs.btrfs -L "ROOT" "${DISK}3" -f

#Bc we crypt so skip this 
# mount -t btrfs "${DISK}3" /mnt
fi


ls /mnt | xargs btrfs subvolume delete
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
umount /mnt



# mount target
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@ -L ROOT /mnt
mkdir -p /mnt/{boot,home,.snapshots,var_log}
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@home -L ROOT /mnt/home
clear
echo " Mount is running"
sleep 5
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@snapshots -L ROOT /mnt/.snapshots
mount -t btrfs -o noatime,compress=zstd:3,space_cache=v2,subvol=@var_log -L ROOT /mnt/var_log


# mkdir -p /mnt/boot/efi
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

# For AMD machine
pacstrap /mnt base base-devel linux linux-firmware git neovim grub amd-ucode openssh --noconfirm --needed

pacstrap /mnt efibootmgr sudo archlinux-keyring wget libnewt networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools reflector base-devel linux-headers --noconfirm --needed

clear
echo "Genfstab"
sleep 5
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

echo "--------------------------------------"
echo "--   SYSTEM READY FOR 0-setup       --"
echo "--------------------------------------"

echo "Now you can run `reboot now`"
echo "to check your system can boot and next installer srcipt"

########################################
# TEST 1 IN VMWARE end
########################################
