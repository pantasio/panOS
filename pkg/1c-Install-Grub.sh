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
## cryptroot d2bd0324-32a3-4218-b2260143a5928678
## cryptroot d2bd0324-32a3-4218-b2260143a5928678
## UEFISYS 0230-7CF0
## UEFISYS 0230-7CF0
## Win10EFI 8054-D939
## Win10EFI 8054-D939
# https://youtu.be/ybvwikNlx9I?t=2002
## p6 4f7301...
vim /etc/default/grub 
#edit
GRUB_CMDLINE_LINUX=""
#to
GRUB_CMDLINE_LINUX="cryptdevice=UUID=${ROOT_UUID}:cryptroot root=/dev/mapper/cryptroot"

line_old='GRUB_CMDLINE_LINUX=""'
line_new='GRUB_CMDLINE_LINUX="cryptdevice=UUID=${ROOT_UUID}:cryptroot root=/dev/mapper/cryptroot"'
sed -i "s%$line_old%$line_new%g" /etc/mkinitcpio.conf


# Add grub menu item for Windows 10 by editing /etc/grub.d/40_custom

cat << EOF >> /etc/grub.d/40_custom
#!/bin/sh
exec tail -n +3 $0
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above.
if [ "${grub_platform}" == "efi" ]; then
  menuentry "Windows 10" {
    insmod part_gpt
    insmod fat
    insmod search_fs_uuid
    insmod chain
    # use:
    # after --set=root, add the EFI partition's UUID
    # this can be found with either:
    #
    # a. blkid
    # - or -
    # b. grub-probe --target=fs_uuid /boot/efi/EFI/VeraCrypt/DcsBoot.efi
    #
    search --fs-uuid --set=root $FS_UUID
    chainloader /EFI/VeraCrypt/DcsBoot.efi
  }
fi


EOF


# 2 điều quan trọng cần chỉnh sủa:
# - [ ] search: Thay $fs-uuid = 88E12-69DD
# - chainloader: cần biết file DcsBoot.efi của win10 ở đâu <- /EFI/BcsBoot.efi or /EFI/VeraCrypt/DcsBoot.efi 







############################
# IMPORTANT MISSTAKE 
############################
# PLS EDIT /ETC/GRUB.D/40_CUSTOM before you run this command below
####

grub-install
grub-mkconfig -o /boot/grub/grub.cfg 

# If Grub cant boot into Win10, let try 
# GRUB_DISABLE_OS_PROBER=false
# and run grub-mkconfig -o /booo/grub/grub.cfg


# Now exit to ISO
exit
# Umount partition
umount -a 
umount -R /mnt

echo "Rebooting in 3 Seconds ..." && sleep 1
echo "Rebooting in 2 Seconds ..." && sleep 1
echo "Rebooting in 1 Second ..." && sleep 1
reboot now
