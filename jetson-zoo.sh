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


#
# check if a particular deb package is installed with dpkg-query
#
function check_deb_package()
{
	local PKG_NAME=$1
	local HAS_PKG=`dpkg-query -W --showformat='${Status}\n' $PKG_NAME|grep "install ok installed"`

	if [ "$HAS_PKG" == "" ]; then
		echo "$LOG_ZOO Checking for '$PKG_NAME' package...not installed"
		return 0
	else
		echo "$LOG_ZOO Checking for '$PKG_NAME' package...installed"
		return 1
	fi
}


#
# install a debian package if it isn't already installed
#
function install_deb_package()
{
	local PKG_NAME=$1
	
	# check to see if the package is already installed
	check_deb_package $PKG_NAME
	local HAS_PKG=$?

	# if not, install the package
	if [ $HAS_PKG == 0 ]; then
		echo "$LOG_ZOO Missing '$PKG_NAME' package...installing '$PKG_NAME' package."
		sudo apt-get --force-yes --yes install $PKG_NAME
	else
		return 1
	fi
	
	# verify that the package was installed
	check_deb_package $PKG_NAME
	local HAS_PKG=$?
	
	if [ $HAS_PKG == 0 ]; then
		echo "$LOG_ZOO Failed to install '$PKG_NAME' package."
		return 0
	else
		echo "$LOG_ZOO Successfully installed '$PKG_NAME' package."
		return 1
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
		

# retrieve jetson board info
function jetson_info() 
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
	JETSON_STORAGE=$(($(stat -f --format="%b*%S" .)))
	JETSON_STORAGE_FREE=$(($(stat -f --format="%f*%S" .)))
	JETSON_STORAGE_USED=$(expr $JETSON_STORAGE - $JETSON_STORAGE_FREE)

	JETSON_STORAGE=$(expr $JETSON_STORAGE / 1048576)	# convert bytes to MB
	JETSON_STORAGE_FREE=$(expr $JETSON_STORAGE_FREE / 1048576)
	JETSON_STORAGE_USED=$(expr $JETSON_STORAGE_USED / 1048576)

	echo "$LOG_ZOO Jetson Storage Total:  $JETSON_STORAGE MB"
	echo "$LOG_ZOO Jetson Storage Used:   $JETSON_STORAGE_USED MB"
	echo "$LOG_ZOO Jetson Storage Free:   $JETSON_STORAGE_FREE MB"

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

		
#
# setup logging
#
{	# run sections in a subshell that we want logged

echo "$LOG_ZOO `date`"
echo "$LOG_ZOO Logging to: $LOG_FILE"


# retrieve jetson info and verify architecture
jetson_info

if [ $? != 0 ]; then
	exit $?
fi

#
# check for dialog package
#
install_deb_package "dialog"
HAS_DIALOG=$?
echo "$LOG_ZOO HAS_DIALOG=$HAS_DIALOG"

#install_deb_package "dialog"

#DIALOG_PKG_OK=$(dpkg-query -W --showformat='${Status}\n' dialog|grep "install ok installed")

#echo "$LOG_ZOO Checking for 'dialog' package: $DIALOG_PKG_OK"

#if [ "" == "$DIALOG_PKG_OK" ]; then
#	echo "$LOG_ZOO 'dialog' package not installed. Setting up 'dialog' package."
#	sudo apt-get --force-yes --yes install dialog
#fi

} > >(tee -i $LOG_FILE) 2>&1		# clear the log on first subshell (tee without -a)

# use customized RC config
export DIALOGRC=./jetson-zoo.rc


#
# package select dialog
#
selected_packages=$(dialog --backtitle "$APP_TITLE" \
	   --title "Packages to Install" \
	   --checklist "Keys:\n  ↑↓ Navigate menu\n  Space to select items\n  Enter to continue" 20 80 7 \
	   --output-fd 1 \
        1 "Hello AI World (jetson-inference)" off \
        2 "TensorFlow 1.13" off \
        3 "PyTorch 1.0 (Python 2.7)" off \
		4 "PyTorch 1.0 (Python 3.6)" off \
		5 "MXNet" off \
		6 "AWS Greengrass" off \
		7 "ROS Melodic" off)

pkg_selection_status=$?
clear
#dialog --clear

{

echo "$LOG_ZOO Packages selection exit status:  $pkg_selection_status"

if [ $pkg_selection_status = 0 ]; then
	if [ -z $selected_packages ]; then
		echo "$LOG_ZOO No packages were selected for installation."
	else
	    echo "$LOG_ZOO Packages selected for installation:  $selected_packages"
	
		for pkg in $selected_packages
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

} > >(tee -a -i $LOG_FILE) 2>&1		# 'tee -a' (append to log on further subshells)

