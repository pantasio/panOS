#!/usr/bin/env bash
# make sure you in arch-chroot
# Create swapfile
truncate -s 0 /swap/swapfile
chattr +C /swap/swapfile
btrfs property set /swap/swapfile compression none
dd if=/dev/zero of=/swap/swapfile bs=100M count=41 status=progress # create 4G
chmod 600 /swap/swapfile
mkswap /swap/swapfile
swapon /swap/swapfile

# Now edit vim /etc/fstab
cat << EOF >> /etc/fstab

# Swapfile
/swap/swapfile none swap defaults 0 0 
EOF

