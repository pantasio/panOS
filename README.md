Co 2 cach cai dat: Makefile va panOS.sh
- makefile toi se cai dat tung buoc
- panOS.sh se tu dong cai tat ca

## Đầu tiên chúng ta cần install init-system. Init system chỉ là Arch với các gói sau:


- Networkmanager  


## Theme 
- Dùng [DTOS](https://gitlab.com/dwt1/dtos) 
- Dùng sddm-sugar-candy to login
  ```
  # Install yay:
  git clone https://aur.archlinux.org/yay.git
  cd yay && makekg -si
  # Install sddm-sugar-candy
  yay -S sddm-sugar-candy

  # Copy default.conf
  sudo cp /usr/lib/sddm/sddm.conf.d/default.conf /etc/sddm.conf
  # Edit sddm.conf to setup sugar-candy theme
  # theme=sugar-candy

  # Fix sddm fullHD
  sudo vim /usr/share/sddm/scripts/Xsetup
  # add line:
  xrandr -s 1920x1080

  ```
- Dung Qtile 
- 

## Các App phải có:
- VScode
- KVM/QEMU
- flutter / dart
- Install fonts 
  - MacOS/linux: https://github.com/ryanoasis/nerd-fonts/blob/master/install.sh
  - Win10: https://github.com/ryanoasis/nerd-fonts/blob/master/install.ps1

### Sample all pkg: 
networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools reflector base-devel linux-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack bash-completion openssh rsync reflector acpi acpi_call tlp virt-manager qemu qemu-arch-extra edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font
