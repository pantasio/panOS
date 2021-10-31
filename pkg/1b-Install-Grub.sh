#!/usr/bin/env bash
# make sure you still in arch-chroot


###########################
# Grub Install

######
# Old way1: Normal
# grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Grub
# grub-mkconfig -o /boot/grub/grub.cfg 

######
# New way: Dual boot Win10 EFI
blkid >> /tmp/id.txt
# look at id.txt you will see
## cryptroot 17b84..
## p5 32dd90..
## p2 8E12-69DD
# https://youtu.be/ybvwikNlx9I?t=2002
## p6 4f7301...
vim /etc/default/grub 
#edit
GRUB_CMDLINE_LINUX=""
#to
GRUB_CMDLINE_LINUX="cryptdevice=UUID=${ROOT_UUID}:cryptroot root=/dev/mapper/cryptroot"

# Add grub menu item for Windows 10 by editing /etc/grub.d/40_custom
# 2 điều quan trọng cần chỉnh sủa:
# - [ ] search: Thay $fs-uuid = 88E12-69DD
# - chainloader: cần biết file DcsBoot.efi của win10 ở đâu <- /EFI/BcsBoot.efi or /EFI/VeraCrypt/DcsBoot.efi 

# PLS EDIT /ETC/GRUB.D/40_CUSTOM before you run this command below
grub-install
grub-mkconfig -o /boot/grub/grub.cfg 



# Now exit to ISO
exit
# Umount partition
umount -a 
umount -R /mnt

echo "Rebooting in 3 Seconds ..." && sleep 1
echo "Rebooting in 2 Seconds ..." && sleep 1
echo "Rebooting in 1 Second ..." && sleep 1
reboot now
