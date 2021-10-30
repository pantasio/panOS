#!/usr/bin/env bash
echo "--------------------------------------"
echo "--          Network Setup           --"
echo "--------------------------------------"
pacman -S networkmanager dhclient openssh --noconfirm --needed
systemctl enable --now NetworkManager
systemctl enable --now sshd

pacman -S --noconfirm pacman-contrib curl
pacman -S --noconfirm reflector rsync

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
iso=$(curl -4 ifconfig.co/country-iso)
echo -e "Setting up $iso mirrors for faster downloads"
echo "You are $iso mirror. If you okay, ReEnter or you can change!"
read -p "Please ReEnter again or Change to 'SG' or 'JP'" iso
reflector -a 48 -c SG -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist



nc=$(grep -c ^processor /proc/cpuinfo)
echo "You have " $nc" cores."
echo "-------------------------------------------------"
echo "Changing the makeflags for "$nc" cores."
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -gt 8000000 ]]; then
sudo sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$nc"/g' /etc/makepkg.conf
echo "Changing the compression settings for "$nc" cores."
sudo sed -i 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g' /etc/makepkg.conf
fi

echo "-------------------------------------------------"
echo " Setup Language to US and set localetime, locale "
echo "-------------------------------------------------"
# Time
# Sample 
# `Europe/Zurich` or `America/Chicago`
# see more run `timedatectl list-timezones | grep Chicago`
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
# timedatectl --no-ask-password set-timezone Asia/Ho_Chi_Minh
# timedatectl --no-ask-password set-ntp 1
# localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
# Sample `de_CH-latin1` or 
# echo "KEYMAP=de_CH-latin1" >> /etc/vconsole.conf
echo "KEYMAP=us" >> /etc/vconsole.conf


# Add new user
if [ $(whoami) = "root"  ];
then
	print_title "CREATE USER ACCOUNT"
	read -p "New user name: " USERNAME
	useradd -m -g users -G wheel -s /bin/bash $USERNAME
    # useradd -m -G wheel,libvirt -s /bin/bash $USERNAME 
	passwd $USERNAME
    #set user as sudo #{{{
        echo "$USERNAME ALL=(ALL) ALL" >> /etc/sudoers.d/$USERNAME
		pacman -S --noconfirm sudo
		# Manual config: Run command `EDITOR=vim visudo` and uncomment wheel...
		## Uncomment to allow members of group wheel to execute any command
		sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /etc/sudoers
		## Same thing without a password (not secure)
		#sed -i '/%wheel ALL=(ALL) NOPASSWD: ALL/s/^#//' /etc/sudoers
	#}}}
    # Copy script to $USERNAME home dir
	cp -R /root/panOS /home/$USERNAME/panOS
    chown -R $USERNAME: /home/$USERNAME/panOS
else
	echo "You are already a user proceed with aur installs"
fi

# Setting root password
# echo root:password | chpasswd
echo "SET ROOT PASSWORD"
passwd root

read -p "Please name your machine:" nameofmachine
echo $nameofmachine > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $nameofmachine.localdomain $nameofmachine" >> /etc/hosts
# Set keymaps
localectl --no-ask-password set-keymap us

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

#Add parallel downloading
sed -i 's/^#Para/Para/' /etc/pacman.conf

#Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^   #//' /etc/pacman.conf
pacman -Sy --noconfirm

echo -e "\nInstalling Base System\n"

KVMQEMU=(
`qemu`
`dhclient`
`openbsd-netcat`
`virt-viewer`
`libvirt`
`dnsmasq`
`dmidecode`
`ebtables`
`virt-install`
`virt-manager`
`bridge-utils`
)
for PKG in "${KVMQEMU[@]}"; do
    echo "INSTALLING: ${PKG}"
    sudo pacman -S "$PKG" --noconfirm --needed
done

pacman -S grub efibootmgr networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools reflector base-devel linux-headers

pacman -S avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack bash-completion openssh rsync reflector acpi acpi_call tlp 

pacman -S virt-manager qemu qemu-arch-extra edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font

echo -e "\nDone!\n"

# Add Kernel modules
# edit 
MODULES=(btrfs amdgpu)

# Grub Install
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Grub
grub-mkconfig -o /boot/grub/grub.cfg 

# Now exit to ISO
exit
# Umount partition
umount -a 


