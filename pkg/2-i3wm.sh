#!/usr/bin/env bash
read -p "   Are you want setting reflector (Y/N):" ASK1
case $ASK1 in

y|Y|yes|Yes|YES)
echo yes
;;

n|N|no|No|NO)
echo no
;;
*)

;;
esac

sudo pacman -Syy reflector
# SG is singapore
sudo reflector -a 48 -c SG -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

# list package
# xorg sorg-xinit i3-wm i3lock i3status i3blocks dmenu 
sudo pacman -S xorg xorg-xinit i3-wm i3lock i3status i3blocks dmenu firefox neovim 

# sudo pacman -S xorg lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings i3 lxappearance nitrogen arandr terminator picom dmenu rofi firefox pcmanfm flatpak python-requests gnome-system-monitor pacman-contrib playerctl pavucontrol python-dbus dunst archlinux-wallpaper awesome-terminal-fonts ttf-font-awesome scrot firefox
# Use rofi <-> dmenu
sudo pacman -R --noconfirm i3lock rofi playerctl 
yay -S --noconfirm bumblebee-status betterlockscreen

# Copy default .xinit
sudo cp /etc/X11/xinit/xinitrc $HOME/.xinitrc

# list files You need config
# - $HOME/.xinitrc
# - $HOME/.config//i3status/i3status.conf 


# Set lauout keyboard
# Run `sudo setxkbmap us`

# set resolution of display
# Run `xrandr --output virtual-1 --mode 1920x1080`
# Or run arandr GUI for xrandr

#Assign Program to Workspaces
# Use `xprop` to know WM_CLASS(STRING)
for_window [class="terminal"] move to workspace $ws1
for_window [class="firefox"] move to workspace $ws2
