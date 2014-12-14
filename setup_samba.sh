#!/bin/bash
clear
echo "################################################"
echo "## Script: setup_samba.sh"
echo "## By: Andrew Herren"
echo "## Date: 11/07/14"
echo "################################################"

conf="/etc/samba/smb.conf"
shopt -s nocasematch

echo -e "\nThis script will help you install and configure Samaba file sharing. Would you like to continue? (y/n)>"
read answer
case "$answer" in
y|yes )
	echo "This script can help with the following options. Which would you like to do?"
	echo "i = install samba.(about 2min)"
	echo "p = create a public samba share visible to anyone on your network."
	echo "h = create a hidden samba share visible only to one user."
	echo "x = exit without changes."
	read answer
	case "$answer" in
	i )
		if [[ "$(whoami)" = "root" ]]; then
		echo "Would you like to update the sources list before continuing? (y/n)>"
		read sources
		echo "Would you like to perform a dist-upgrade before continuing? (y/n)>"
		read upgr
		echo "Would you like to perform autoremove to get rid of old/unused packages before continuing? (y/n)>"
		read autor
		case "$sources" in
		y|yes )
			echo "Performing update to sources list..."
			apt-get -q -y update
			;;
		* )
			echo "Skipping update to sources list..."
			;;
		esac
		case "$upgr" in
		y|yes)
			echo "Performing dist-upgrade..."
			apt-get -q -y dist-upgrade
			;;
		* )
			echo "Skipping dist-upgrade..."
			;;
		esac
		case "$autor" in
		y|yes )
			echo "Performing autoremove..."
			apt-get -q -y autoremove
			;;
		* )
			echo "Skipping autremove..."
			;;
		esac
			apt-get -q -y install samba samba-common-bin
			mv /etc/samba/smb.conf /etc/samba/smb.conf.old
			awk 'BEGIN{x=0}//{
				if(($0~/homes/ || 
					/comment = Home Directories/ ||
					/browseable = no/ ||
					/valid users = \%S/ ||
					/read only = yes/ ||
					/create mask = 0700/ ||
					/directory mask = 0700/)&&($0!~/;/)&&(x<7)){
					print "#"$0;
					x++;
				}
				else{
					print $0;
				}}' /etc/samba/smb.conf.old > /etc/samba/smb.conf
			echo "Samba has been installed, please rerun this script if you would like help creating shares."
		else
			echo "This option must be run as root. Please try again using sudo."
		fi
		;;
	p )
		if [[ "$(whoami)" = "root" ]]; then
			echo "Enter full path to the directory to share publicly. >"
			read samba_dir
			if [[ -d "$samba_dir" ]]; then
				echo "Directory found."
			else
				echo "Creating directory "$samba_dir"."
				mkdir -p $samba_dir
			fi
			if [[ -e "$conf" ]]; then
				echo "Please enter a display name for this share. >"
				read name
				chmod 777 $samba_dir
				cp $conf /etc/samba/smb.conf.old
				echo "" >> $conf
				echo "["$name"]" >> $conf
				echo "path = "$samba_dir >> $conf
				echo "create mask = 0777" >> $conf
				echo "directory mask = 0777" >> $conf
				echo "read only = no" >> $conf
				echo "browsable = yes" >> $conf
				echo "guest ok = yes" >> $conf
				echo $conf" file updated. Restarting samba service..."
				/etc/init.d/samba restart
				echo "Finished creating public share."
			else
				echo $conf" file not found. Are you sure samba has been installed? No changes made!"
			fi
		else
			echo "This option must be run as root. Please try again using sudo."
		fi
		;;
	h )
		if [[ "$(whoami)" = "root" ]]; then
			echo "Enter full path to the directory to share privatly. >"
			read samba_dir
			if [[ -d "$samba_dir" ]]; then
				echo "Directory found."
			else
				echo "Creating directory "$samba_dir"."
				mkdir -p $samba_dir
			fi
			if [[ -e "$conf" ]]; then
				echo "Please enter a display name for this share. >"
				read name
				chmod 700 $samba_dir
				echo "Please enter the user who may access this share. >"
				read user
				if id -u $user >/dev/null 2>&1; then
					chown $user:$user $samba_dir
					chown_done=1
				else
					chown_done=0
				fi	
				cp $conf /etc/samba/smb.conf.old
				echo "" >> $conf
				echo "["$name"]" >> $conf
				echo "path = "$samba_dir >> $conf
				echo "valid users = "$user >> $conf
				echo "create mask = 0700" >> $conf
				echo "directory mask = 0700" >> $conf
				echo "read only = no" >> $conf
				echo "browsable = no" >> $conf
				echo $conf" file updated. Restarting samba service..."
				/etc/init.d/samba restart
				echo "Finished restarting."
				if [[ $chown_done == 0 ]]; then
					echo "Ensure that user "$user" is been created before use."
					echo "To check registered users type:"
					echo "sudo pdbedit -L -v"
					echo "To create a new user type:"
					echo "sudo useradd "$user" -m -G usergroup"
					echo "sudo passwd "$user
					echo "sudo smbpasswd -a "$user
					echo "finally, to change ownership of "$samba_dir" to "$user" type:"
					echo "sudo chown "$user":"$user" "$samba_dir
				else
					echo "I have confirmed that user "$name" exists and have made them the owner of "$samba_dir"."
					echo "Please remember to add them to the samba password file if you have not yet done so by"
					echo "typing:"
					echo "sudo smbpasswd -a "$user
				fi
			else
				echo $conf" file not found. Are you sure samba has been installed? No changes have been made!"
			fi
		else
			echo "This option must be run as root. Please try again using sudo."
		fi
		;; 
	* )
		echo "Exiting without changes."
	esac
	;;
* )
	echo "Exiting without changes."
	;;
esac
shopt -u nocasematch
