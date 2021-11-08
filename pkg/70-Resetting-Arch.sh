#!/usr/bin/env bash
# disable your gdm, sddm, li ... 
sudo systemctl disable gdm

sudo pacman -D  --asdeps $(pacman -Qqe)
sudo pacman -D  --asexplicit base linux-lts linux-formware git neovim amd-ucode 
su -

# Now remove everything
pacman -Qttdq | pacman -Rns -

echo "Now exec 71-reset.sh"



