Co 2 cach cai dat: Makefile va panOS.sh
- makefile toi se cai dat tung buoc
- panOS.sh se tu dong cai tat ca
## Thông tin về panOS
- File system: btrfs 
- Dual boot with Win10
- Snapshot
- 4G swapfile 

## Đầu tiên chúng ta cần install init-system. Init system chỉ là Arch với các gói sau:
All setting is minimal, các bước cài từ 0-preinstall.sh -> 1d-swapfile.sh
Để xem thông tin chi tiết các bạn xem ở minimal-system.md.
- [ ] install driver on GT730 as host - 1 FullHD BenQ monitor.
  - [ ] Install driver can use `nvidia-smi` https://www.youtube.com/watch?v=DVBepR-YhLs
- [ ] systemctl enable NetworkManager
- [ ] systemctl enable sshd
- [ ] setting wlan static IPv4 192.168.100.90
- [ ] backup snapshot with one-drive
- [ ] Save dotfile with git and one-drive
- [ ] 


## Theme 
- Dùng [DTOS](https://gitlab.com/dwt1/dtos) 
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
- 

## Các App phải có:
- VScode
- KVM/QEMU
- flutter / dart
- Install fonts 
  - MacOS/linux: https://github.com/ryanoasis/nerd-fonts/blob/master/install.sh
  - Win10: https://github.com/ryanoasis/nerd-fonts/blob/master/install.ps1

### Sample all pkg: 
networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools reflector base-devel linux-headers 
avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils 
bluez bluez-utils cups hplip alsa-utils 

bash-completion openssh rsync reflector acpi acpi_call tlp 
virt-manager qemu qemu-arch-extra edk2-ovmf bridge-utils dnsmasq vde2 
openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font
