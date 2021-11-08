#!/bin/bash

#ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
#hwclock --systohc
#sed -i '177s/.//' /etc/locale.gen
#locale-gen
#echo "LANG=en_US.UTF-8" >> /etc/locale.conf
#echo "KEYMAP=de_CH-latin1" >> /etc/vconsole.conf
#echo "arch" >> /etc/hostname
#echo "127.0.0.1 localhost" >> /etc/hosts
#echo "::1       localhost" >> /etc/hosts
#echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
#echo root:password | chpasswd

# You can add xorg to the installation packages, I usually add it at the DE or WM install script
# You can remove the tlp package if you are installing on a desktop or vm

pacman -S grub efibootmgr networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools reflector base-devel linux-headers 

# avahi - Network tools DNS
# https://wiki.archlinux.org/title/avahi
pacman -S avahi
systemctl enable avahi-daemon

xdg-user-dirs xdg-utils gvfs gvfs-smb 
nfs-utils inetutils dnsutils 
bluez bluez-utils 
cups hplip 
alsa-utils 

# PipeWire is a new low-level multimedia framework. It aims to offer capture and playback for both audio and video with minimal latency and support for PulseAudio, JACK, ALSA and GStreamer-based applications.
# pipewire pipewire-alsa pipewire-jack

bash-completion openssh rsync reflector acpi acpi_call 


# Desktop


# laptop
pacman -S tlp
# is a feature-rich command line utility for Linux, saving laptop battery power
systemctl enable tlp # You can comment this command out if you didn't install tlp, see above


# virt-manager qemu qemu-arch-extra edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font

# pacman -S --noconfirm xf86-video-amdgpu
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings


# Install Grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd


systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable libvirtd
systemctl enable firewalld
systemctl enable acpid

printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"




