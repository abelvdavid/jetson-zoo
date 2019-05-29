#!/bin/bash
#
# Copyright (c) 2019, NVIDIA CORPORATION. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#


APP_TITLE="NVIDIA Jetson Add-On Installer"

LOG_ZOO="[jetson-zoo] "
LOG_FILE=./jetson-zoo.log

UPDATES_URL="https://raw.githubusercontent.com/dusty-nv/jetson-zoo/master/jetson-zoo.sh"

#
# check for updates to this script
#
function check_updates()
{
	CHECKSUM=sha256sum

	NEW_PATH="jetson-zoo.new"
	OLD_PATH="jetson-zoo.old"
	CUR_PATH=$0

	echo "$LOG_ZOO checking for updates..."
	echo "$LOG_ZOO current path: $CUR_PATH  old path: $OLD_PATH  new path: $NEW_PATH"

	# make a backup of the current script
	echo "$LOG_ZOO backing up $CUR_PATH to $OLD_PATH"
	cp $CUR_PATH $OLD_PATH

	# download the latest
	echo "$LOG_ZOO downloading latest script to $NEW_PATH"
	wget --no-check-certificate "$UPDATES_URL" -O $NEW_PATH

	# get checksums
	CHECKSUM_OLD=$(sha256sum $CUR_PATH | awk '{print $1}')
	CHECKSUM_NEW=$(sha256sum $NEW_PATH | awk '{print $1}')

	echo "$LOG_ZOO old checksum: $CHECKSUM_OLD"
	echo "$LOG_ZOO new checksum: $CHECKSUM_NEW"

	# compare checksums
	if [ $CHECKSUM_OLD != $CHECKSUM_NEW ]; then
		echo "$LOG_ZOO updated version found"
		return 1
	fi

	echo "$LOG_ZOO already using the latest version"
	return 0
}


#
# check if a particular deb package is installed with dpkg-query
# arg $1 -> package name
# arg $2 -> variable name to output status to (e.g. HAS_PACKAGE=1)
#
function find_deb_package()
{
	local PKG_NAME=$1
	local HAS_PKG=`dpkg-query -W --showformat='${Status}\n' $PKG_NAME|grep "install ok installed"`

	if [ "$HAS_PKG" == "" ]; then
		echo "$LOG_ZOO Checking for '$PKG_NAME' deb package...not installed"
	else
		echo "$LOG_ZOO Checking for '$PKG_NAME' deb package...installed"
		eval "$2=INSTALLED"
	fi
}


#
# install a debian package if it isn't already installed
# arg $1 -> package name
# arg $2 -> variable name to output status to (e.g. FOUND_PACKAGE=INSTALLED)
#
function install_deb_package()
{
	local PKG_NAME=$1
	
	# check to see if the package is already installed
	find_deb_package $PKG_NAME $2

	# if not, install the package
	if [ -z $2 ]; then
		echo "$LOG_ZOO Missing '$PKG_NAME' deb package...installing '$PKG_NAME' package."
		sudo apt-get --force-yes --yes install $PKG_NAME
	else
		return 0
	fi
	
	# verify that the package was installed
	find_deb_package $PKG_NAME $2
	
	if [ -z $2 ]; then
		echo "$LOG_ZOO Failed to install '$PKG_NAME' deb package."
		return 1
	else
		echo "$LOG_ZOO Successfully installed '$PKG_NAME' deb package."
		return 0
	fi
}

#
# install Hello AI World
#
function install_jetson_inference() 
{
	jetson_inference_path=~/jetson-inference
	jetson_inference_path=$(dialog --backtitle "$APP_TITLE" --output-fd 1 --inputbox "Path to install jetson-inference:" 20 80 $jetson_inference_path)
	
	jetson_inference_path_status=$?

	for i in {1..5}; do echo ""; done
				
	echo "$LOG_ZOO jetson-inference path selection exit status:  $jetson_inference_path_status"
	
	if [ $jetson_inference_path_status = 0 ]; then
		echo "$LOG_ZOO jetson-inference path:  $jetson_inference_path"
	fi
}			
		

#
# package installation menu
#
function install_packages()
{
	pkg_selected=$(dialog --backtitle "$APP_TITLE" \
						  --title "Install Add-On Packages" \
						  --checklist "Keys:\n  ↑↓  Navigate Menu\n  Space to Select Packages \n  Enter to Continue" 20 80 10 \
						  --output-fd 1 \
						  1 "Hello AI World (jetson-inference)" off \
						  2 "TensorFlow 1.13" off \
						  3 "PyTorch 1.0 (Python 2.7)" off \
						  4 "PyTorch 1.0 (Python 3.6)" off \
						  5 "Caffe2" off \
						  6 "MXNet" off \
						  7 "ROS Melodic" off \
						  8 "ros_deep_learning" off \
						  9 "Gazebo" off \
						  10 "AWS Greengrass" off )

	pkg_selection_status=$?
	clear

	{

	echo "$LOG_ZOO Packages selection status:  $pkg_selection_status"

	if [ $pkg_selection_status = 0 ]; then
		if [ -z $pkg_selected ]; then
			echo "$LOG_ZOO No packages were selected for installation."
		else
		    echo "$LOG_ZOO Packages selected for installation:  $pkg_selected"
		
			for pkg in $pkg_selected
			do
				if [ $pkg = 1 ]; then
					echo "$LOG_ZOO Installing Hello AI World (jetson-inference)..."
					install_jetson_inference
				elif [ $pkg = 2 ]; then
					echo "$LOG_ZOO Installing TensorFlow 1.13 (Python 3.6)..."
				elif [ $pkg = 3 ]; then
					echo "$LOG_ZOO Installing PyTorch 1.0 (Python 2.7)..."
				elif [ $pkg = 4 ]; then
					echo "$LOG_ZOO Installing PyTorch 1.0 (Python 3.6)..."
				elif [ $pkg = 5 ]; then
					echo "$LOG_ZOO Installing MXNet..."
				elif [ $pkg = 6 ]; then
					echo "$LOG_ZOO Installing AWS Greengrass..."
				elif [ $pkg = 7 ]; then
					echo "$LOG_ZOO Installing ROS Melodic..."
				fi
			done
		fi
	else
	    echo "$LOG_ZOO Package selection cancelled."
	fi

	echo "$LOG_ZOO Press Enter key to quit."

	} > >(tee -a -i $LOG_FILE) 2>&1

}


# 
# retrieve jetson board info
#
function read_jetson_info() 
{
	# verify architecture 
	JETSON_ARCH=$(uname -i)
	ARCH_REQUIRED="aarch64"

	echo "$LOG_ZOO System Architecture:  $JETSON_ARCH"

	if [ $JETSON_ARCH != $ARCH_REQUIRED ]; then
		echo "$LOG_ZOO $JETSON_ARCH architecture detected, $ARCH_REQUIRED required"
		echo "$LOG_ZOO Please run jetson-zoo from the Jetson ($ARCH_REQUIRED)"
		return 1
	fi

	# Tegra Chip ID
	JETSON_CHIP_ID=$(cat /sys/module/tegra_fuse/parameters/tegra_chip_id)

	case $JETSON_CHIP_ID in
		64)
			JETSON_CHIP_ID="T124"
			JETSON_CHIP="TK1" ;;
		33)
			JETSON_CHIP_ID="T210"
			JETSON_CHIP="TX1" ;;
		24)
			JETSON_CHIP_ID="T186"
			JETSON_CHIP="TX2" ;;
		25)
			JETSON_CHIP_ID="T194"
			JETSON_CHIP="Xavier" ;;
		*)
			JETSON_CHIP="UNKNOWN" ;;
	esac

	echo "$LOG_ZOO Jetson Chip ID: $JETSON_CHIP ($JETSON_CHIP_ID)"

	# Board model
	JETSON_MODEL=$(tr -d '\0' < /sys/firmware/devicetree/base/model)	 # remove NULL bytes to avoid bash warning
	echo "$LOG_ZOO Jetson Board Model: $JETSON_MODEL"

	# Serial number
	JETSON_SERIAL=$(tr -d '\0' < /sys/firmware/devicetree/base/serial-number)  # remove NULL bytes to avoid bash warning
	echo "$LOG_ZOO Jetson Serial Number:  $JETSON_SERIAL"

	# Active power mode
	JETSON_POWER_MODE=$(nvpmodel -q | head -n 1 | sed 's/\NV Power Mode: //g')
	echo "$LOG_ZOO Jetson Active Power Mode:  $JETSON_POWER_MODE"

	# Memory capacity/usage
	JETSON_MEMORY=$(free --mega | awk '/^Mem:/{print $2}')
	JETSON_MEMORY_USED=$(free --mega | awk '/^Mem:/{print $3}')
	JETSON_MEMORY_FREE=$(expr $JETSON_MEMORY - $JETSON_MEMORY_USED)

	echo "$LOG_ZOO Jetson Memory Total:  $JETSON_MEMORY MB"
	echo "$LOG_ZOO Jetson Memory Used:   $JETSON_MEMORY_USED MB"
	echo "$LOG_ZOO Jetson Memory Free:   $JETSON_MEMORY_FREE MB"
	
	# Disk storage
	JETSON_DISK=$(($(stat -f --format="%b*%S" .)))
	JETSON_DISK_FREE=$(($(stat -f --format="%f*%S" .)))
	JETSON_DISK_USED=$(expr $JETSON_DISK - $JETSON_DISK_FREE)

	JETSON_DISK=$(expr $JETSON_DISK / 1048576)	# convert bytes to MB
	JETSON_DISK_FREE=$(expr $JETSON_DISK_FREE / 1048576)
	JETSON_DISK_USED=$(expr $JETSON_DISK_USED / 1048576)

	echo "$LOG_ZOO Jetson Disk Total:  $JETSON_DISK MB"
	echo "$LOG_ZOO Jetson Disk Used:   $JETSON_DISK_USED MB"
	echo "$LOG_ZOO Jetson Disk Free:   $JETSON_DISK_FREE MB"

	# Kernel version
	JETSON_KERNEL=$(uname -r)
	echo "$LOG_ZOO Jetson L4T Kernel Version:  $JETSON_KERNEL"

	# L4T version
	local JETSON_L4T_STRING=$(head -n 1 /etc/nv_tegra_release)

	JETSON_L4T_RELEASE=$(echo $JETSON_L4T_STRING | cut -f 2 -d ' ' | grep -Po '(?<=R)[^;]+')
	JETSON_L4T_REVISION=$(echo $JETSON_L4T_STRING | cut -f 2 -d ',' | grep -Po '(?<=REVISION: )[^;]+')
	
	JETSON_L4T="$JETSON_L4T_RELEASE.$JETSON_L4T_REVISION"

	echo "$LOG_ZOO Jetson L4T BSP Version:  L4T R$JETSON_L4T"

	# JetPack version
	case $JETSON_L4T in
		"32.1.0") JETSON_JETPACK="4.2" ;;
		"31.1.0") JETSON_JETPACK="4.1.1" ;;
		"31.0.2") JETSON_JETPACK="4.1" ;;
		"31.0.1") JETSON_JETPACK="4.0" ;;
		"28.2.1") JETSON_JETPACK="3.3 | 3.2.1" ;;
		"28.2" | "28.2.0" ) JETSON_JETPACK="3.2" ;;
		"28.1") JETSON_JETPACK="3.1" ;;
		"27.1") JETSON_JETPACK="3.0" ;;
		"24.2") JETSON_JETPACK="2.3" ;;
		"24.1") JETSON_JETPACK="2.2.1 | 2.2" ;;
		"23.2") JETSON_JETPACK="2.1" ;;
		"23.1") JETSON_JETPACK="2.0" ;;
		"21.5") JETSON_JETPACK="2.3.1 | 2.3" ;;
		"21.4") JETSON_JETPACK="2.2 | 2.1 | 2.0 | 1.2" ;;
		"21.3") JETSON_JETPACK="1.1" ;;
		"21.2") JETSON_JETPACK="1.0" ;;
		*)      JETSON_JETPACK="UNKNOWN" ;;
	esac

	echo "$LOG_ZOO Jetson JetPack Version:  JetPack $JETSON_JETPACK"

	# CUDA version
	if [ -f /usr/local/cuda/version.txt ]; then
		JETSON_CUDA=$(cat /usr/local/cuda/version.txt | sed 's/\CUDA Version //g')
	else
		JETSON_CUDA="NOT_INSTALLED"
	fi

	echo "$LOG_ZOO Jetson CUDA Version:  CUDA $JETSON_CUDA"

	return 0
}


# display jetson board info
function jetson_info()
{
	echo "$LOG_ZOO Jetson Board Information"

	local mem_total_str=$(printf "│  Total:  %4d MB  │" ${JETSON_MEMORY})
	local mem_used_str=$(printf "│  Used:   %4d MB  │" ${JETSON_MEMORY_USED})
	local mem_free_str=$(printf "│  Free:   %4d MB  │" ${JETSON_MEMORY_FREE})

	local disk_total_str=$(printf "│  Total:  %5d MB  │" ${JETSON_DISK})
	local disk_used_str=$(printf "│  Used:   %5d MB  │" ${JETSON_DISK_USED})
	local disk_free_str=$(printf "│  Free:   %5d MB  │" ${JETSON_DISK_FREE})

	local sw_kernel_str=$(printf  "│  Linux Kernel:     %-23s│" "$JETSON_KERNEL ($JETSON_ARCH)")
	local sw_l4t_str=$(printf     "│  L4T Version:      %-23s│" "$JETSON_L4T")
	local sw_jetpack_str=$(printf "│  JetPack Version:  %-23s│" "$JETSON_JETPACK")
	local sw_cuda_str=$(printf    "│  CUDA Version:     %-23s│" "$JETSON_CUDA")

	local info_str="Part Name:  $JETSON_MODEL\n
Chip Arch:  $JETSON_CHIP ($JETSON_CHIP_ID)\n
Serial No:  $JETSON_SERIAL\n
Power Mode: $JETSON_POWER_MODE\n\n
┌─\ZbSoftware Configuration\ZB────────────────────┐\n
${sw_kernel_str}\n
${sw_l4t_str}\n
${sw_jetpack_str}\n
${sw_cuda_str}\n
└───────────────────────────────────────────┘\n\n
┌─\ZbMemory\ZB────────────┐  ┌─\ZbDisk Storage\ZB───────┐\n
${mem_total_str}  ${disk_total_str}\n
${mem_used_str}  ${disk_used_str}\n
${mem_free_str}  ${disk_free_str}\n
└───────────────────┘  └────────────────────┘\n"  

	dialog --backtitle "$APP_TITLE" \
		  --title "Jetson Board Information" \
		  --colors \
		  --msgbox "$info_str" 22 85 
}


		
# initial config
{	
	#
	# run sections that we want logged in a subshell 
	#
	echo "$LOG_ZOO `date`"
	echo "$LOG_ZOO Logging to: $LOG_FILE"


	# 
	# retrieve jetson info and verify architecture
	#
	read_jetson_info

	if [ $? != 0 ]; then
		exit $?
	fi


	#
	# check for dialog package
	#
	install_deb_package "dialog" FOUND_DIALOG
	echo "$LOG_ZOO FOUND_DIALOG=$FOUND_DIALOG"


	#
	# check for updates
	#
	check_updates
	version_updated=$?

} > >(tee -i $LOG_FILE) 2>&1		# clear the log on first subshell (tee without -a)


# use customized RC config
export DIALOGRC=./jetson-zoo.rc


# if an update occured, exit this instance of the script
echo "TEST TEST"
echo "$LOG_ZOO version updated:  $version_updated"

if [ $version_updated != 0 ]; then
	dialog --backtitle "$APP_TITLE" --title "Update Notification" --yesno "\nAn updated version of this script is available.\n\nWould you like for it to be downloaded now?" 10 55

	update_status=$?

	if [ $update_status == 0 ]; then
		echo "$LOG_ZOO applying update ($NEW_PATH -> $CUR_PATH)..."
		#cp $NEW_PATH $CUR_PATH
		#$CUR_PATH $@
		exit 0
	fi
	#echo "$LOG_ZOO finished updating, restarting script"
fi






#
# main menu
#
while true; do
	menu_selected=$(dialog --backtitle "$APP_TITLE" \
					   --title "Main Menu" \
					   --cancel-label "Quit" \
					   --menu "Keys:\n  ↑↓  Navigate Menu\n  Enter to Continue" 20 80 7 \
					   --output-fd 1 \
						1 "Install Add-On Packages" \
						2 "Uninstall Add-On Packages" \
						3 "View Installed Add-Ons" \
						4 "View Board Information" \
						5 "Check for Updates" )

	menu_status=$?
	clear

	{
		echo "$LOG_ZOO Menu status:   $menu_status"

		# non-zero exit code means the user quit
		if [ $menu_status != 0 ]; then
			echo "$LOG_ZOO Press Enter key to exit"
			exit 0
		fi

		echo "$LOG_ZOO Menu selected: $menu_selected"

	} > >(tee -a -i $LOG_FILE) 2>&1		# 'tee -a' (append to log on further subshells)


	# execute the selected menu option
	case $menu_selected in
		1)
			echo "$LOG_ZOO Install Add-On Packages" 
			install_packages ;;
		2)
			echo "$LOG_ZOO Uninstall Add-On Packages" ;;
		3)
			echo "$LOG_ZOO View Installed Add-Ons" ;;
		4)
			echo "$LOG_ZOO View Board Information" 
			jetson_info ;;
		5)
			echo "$LOG_ZOO Check for Updates" ;;
		*)
			echo "$LOG_ZOO Unknown Menu Option" ;;
	esac
done

