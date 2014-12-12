#!/bin/bash
clear
echo "################################################"
echo "## Script: setup_hdAutoMount.sh"
echo "## By: Andrew Herren"
echo "## Date: 11/07/14"
echo "################################################"

shopt -s nocasematch
echo -e "\nThis script will display a list of currently unmounte disks and will allow"
echo "the user to assocaite them with a mountpoint. It will then create an fstab entry"
echo "using the disks UUID so that it will always be mounted even if it is not always"
echo "detected with the same identifier (eg sda, sdb, etc)."
echo "Would you like to continue? (y/n)>"
read answer
case "$answer" in
y|yes )
	if [[ $(whoami) = "root" ]]; then
		echo "---Installed disks that are not currently mounted---"
		ls -l /dev/disk/by-uuid | awk '/^l/{print "/dev/"substr($11,7,length($11))}' | xargs lsblk | awk '{if($1~/^NAME/)print $1"\t"$4; else if($7!~/./)print $1"\t"$4;}'
		echo "Please type the name of the disk that you would like to automount exactly as it appears above"
		echo "or type q to quit. >"
		read part
		if [[ $part != "q" ]]; then
			disk="/dev/"$part
			echo "Please enter the full path to mount the disk to. >"
			read dir
			uuid=$(blkid | awk -v disk="$disk" '//{if($0 ~ disk)print substr($2,7,length($2)-7)}')
			fs_type=$(blkid | awk -v disk="$disk" '//{if($0 ~ disk) print substr($3,7,length($3)-7)}')
			if [[ "$uuid" = "" ]]; then
				echo "Disk not found. Exiting."
			else
				if [[ ! -d "$dir" ]]; then
					mkdir -p $dir;
				fi
				echo "Updating /etc/fstab..."
				echo -e "UUID="$uuid"\t"$dir"\t"$fs_type"\tdefaults,noatime\t0\t0" >> /etc/fstab
				echo "Mounting all drives in /etc/fstab..."
				mount -all
				echo "Done."
			fi
		else
			echo "Exiting without changes."
		fi
	else
		echo "This script must be run as root. Please try again using sudo."
	fi
	;;
* )
	echo "Exiting without changes."
	;;
esac
shopt -u nocasematch
