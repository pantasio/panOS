#!/usr/bin/env bash
# (If running under VMWare) Install VM tools
# pacman -S open-vm-tools
# pacman -S open-vm-tools-dkms
# Check pacman output for the dkms version that needs to be installed, then

# dkms add open-vm-tools/9.4.0
# Start + Enable the daemon

# cat /proc/version > /etc/arch-release
# systemctl start vmtoolsd
# systemctl enable vmtoolsd
# (optional) Sync time to the host, alternatively set up NTP

# vmware-toolbox-cmd timesync enable



