#!/usr/bin/env bash

function question_for_answer(){ #{{{
	read -p "$1 [y][n]: " OPTION
	echo ""
} #}}}
function install_status(){ #{{{
	if [ $? -ne 0 ] ; then
		CURRENT_STATUS=-1
	else
		CURRENT_STATUS=1
	fi
} #}}}
function print_line(){ #{{{
	echo "--------------------------------------------------------------------------------"
} #}}}
function print_title (){ #{{{
	clear
	echo "#-------------------------------------------------------------------------------"
	echo -e "# $1"
	echo "#-------------------------------------------------------------------------------"
	echo ""
} #}}}
function add_new_daemon(){ #{{{
	remove_daemon "$1"
	sed -i '/DAEMONS[=]/s/\(.*\)\>/& '"$1"'/' /etc/rc.conf
} #}}}
function remove_daemon(){ #{{{
	sed -i '/DAEMONS[=]/s/'"$1"' //' /etc/rc.conf
} #}}}
function add_new_module(){ #{{{
	remove_module "$1"
	sed -i '/MODULES[=]/s/\(.*\)\>/& '"$1"'/' /etc/rc.conf
	#sed -i '/MODULES[=]/s/^[^ ]*\>/& '"$1"'/' /etc/rc.conf
} #}}}
function remove_module(){ #{{{
	sed -i '/MODULES[=]/s/'"$1"' //' /etc/rc.conf
} #}}}
function finish_function(){ #{{{
	print_line
	echo "Continue with RETURN"
	read
	clear
} #}}}
function sumary(){ #{{{
	case $CURRENT_STATUS in
		0)
			print_line
			echo "$1 not successfull (Canceled)"
			;;
		-1)
			print_line
			echo "$1 not successfull (Error)"
			;;
		1)
			print_line
			echo "$1 successfull"
			;;
		*)
			print_line
			echo "WRONG ARG GIVEN"
			;;
	esac
} #}}}

#base system #{{{
    print_title "TERMINAL TOOLS - https://wiki.archlinux.org/index.php/Bash"
	pacman -S --noconfirm --needed curl rsync mlocate bash-completion vim neovim
	# maybe this is old
    pacman -S --noconfirm --needed bc
 
    print_title "(UN)COMPRESS TOOLS - https://wiki.archlinux.org/index.php/P7zip"
	pacman -S --noconfirm --needed unzip unrar p7zip 
    pacman -S --noconfirm --needed tar gzip bzip2
	
    # I dont see Dbus in Titus
    print_title "DBUS - https://wiki.archlinux.org/index.php/D-Bus"
	pacman -S --noconfirm --needed dbus
	add_new_daemon "dbus"
	
    print_title "ACPI - https://wiki.archlinux.org/index.php/ACPI_modules"
	pacman -S --noconfirm --needed acpi acpid
	add_new_daemon "acpid"
	
    #TLP #{{{
	print_title "TLP - https://wiki.archlinux.org/index.php/TLP"
	question_for_answer "Install TLP (great battery improvement on laptops)"
	case "$OPTION" in
		"y")
			su -l $USERNAME --command="yaourt -S --noconfirm tlp"
			add_new_daemon "@tlp"
			install_status
			;;
		*)
			CURRENT_STATUS=0
			;;
	esac
	sumary "TLP installation"
	finish_function
	#}}}
	
    print_title "CUPS - https://wiki.archlinux.org/index.php/Cups"
	pacman -S --noconfirm --needed cups ghostscript gsfonts
	pacman -S --noconfirm --needed gutenprint foomatic-db foomatic-db-engine foomatic-db-nonfree foomatic-filters hplip splix cups-pdf
	add_new_daemon "@cupsd"
	
    print_title "NTFS/FAT - https://wiki.archlinux.org/index.php/Ntfs"
	pacman -S --noconfirm --needed ntfs-3g ntfsprogs dosfstools
    pacman -S --noconfirm --needed exfat-utils
	
    print_title "SSH - https://wiki.archlinux.org/index.php/Ssh"
	pacman -S --noconfirm --needed rssh openssh
	add_new_daemon "@sshd"
	#configure ssh/samba #{{{
		echo -e "sshd: ALL\n# End of file" > /etc/hosts.allow
		echo -e "ALL: ALL: DENY\n# End of file" > /etc/hosts.deny
		#ssh_conf #{{{
			sed -i '/ListenAddress/s/^#//' /etc/ssh/sshd_config
			sed -i '/SyslogFacility/s/^#//' /etc/ssh/sshd_config
			sed -i '/LogLevel/s/^#//' /etc/ssh/sshd_config
			sed -i '/LoginGraceTime/s/^#//' /etc/ssh/sshd_config
			sed -i '/PermitRootLogin/s/^#//' /etc/ssh/sshd_config
			sed -i '/StrictModes/s/^#//' /etc/ssh/sshd_config
			sed -i '/RSAAuthentication/s/^#//' /etc/ssh/sshd_config
			sed -i '/PubkeyAuthentication/s/^#//' /etc/ssh/sshd_config
			sed -i '/IgnoreRhosts/s/^#//' /etc/ssh/sshd_config
			sed -i '/PermitEmptyPasswords/s/^#//' /etc/ssh/sshd_config
			sed -i '/X11Forwarding/s/^#//' /etc/ssh/sshd_config
			sed -i '/X11Forwarding/s/no/yes/' /etc/ssh/sshd_config
			sed -i '/X11DisplayOffset/s/^#//' /etc/ssh/sshd_config
			sed -i '/X11UseLocalhost/s/^#//' /etc/ssh/sshd_config
			sed -i '/PrintMotd/s/^#//' /etc/ssh/sshd_config
			sed -i '/PrintMotd/s/yes/no/' /etc/ssh/sshd_config
			sed -i '/PrintLastLog/s/^#//' /etc/ssh/sshd_config
			sed -i '/TCPKeepAlive/s/^#//' /etc/ssh/sshd_config
			sed -i '/the setting of/s/^/#/' /etc/ssh/sshd_config
			sed -i '/RhostsRSAAuthentication and HostbasedAuthentication/s/^/#/' /etc/ssh/sshd_config
			sed -i 's/ListenAddress ::/s/^/#/' /etc/ssh/sshd_config
		#}}}
	#}}}
	
    print_title "SAMBA - https://wiki.archlinux.org/index.php/Samba"
	pacman -S --noconfirm --needed samba
	cp /etc/samba/smb.conf.default /etc/samba/smb.conf
	add_new_daemon "@samba"
	
    print_title "ALSA - https://wiki.archlinux.org/index.php/Alsa"
	pacman -S --noconfirm --needed alsa-utils alsa-plugins pulseaudio pulseaudio-alsa pulseaudio-bluetooth
    # pacman -S --noconfirm --needed pavucontrol

	sed -i '/MODULES[=]/s/snd-usb-audio//' /etc/rc.conf
	sed -i '/MODULES[=]/s/MODULES[=](/&snd-usb-audio/' /etc/rc.conf
	add_new_daemon "@alsa"

    # pacman -S --noconfirm --needed

    print_title "Network Tools"
    pacman -S --noconfirm --needed net-tools openconnect networkmanager-openconnect

    print_title "Docker"
	pacman -S --noconfirm --needed docker ansible terraform
	# add_new_daemon "@docker"

    #################
    # We dont need install YAY bc we can install by script `install-aur-packages.sh`
    # We need install GO????
    # AUR pkg
    # Install yay
    pacman -S --noconfirm --needed go
    git clone https://aur.archlinux.org/yay
    cd yay
    makepkg -si


#}}}