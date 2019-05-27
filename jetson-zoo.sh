#!/bin/bash

APP_TITLE="NVIDIA Jetson Add-On Installer"

#
# install Hello AI World
#
function install_jetson_inference() {
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
# setup logging
#
LOG_ZOO="[jetson-zoo] "
LOG_FILE=./jetson-zoo.log

{	# run sections in a subshell that we want logged

echo "$LOG_ZOO `date`"
echo "$LOG_ZOO Logging to: $LOG_FILE"


#
# check for dialog package
#
DIALOG_PKG_OK=$(dpkg-query -W --showformat='${Status}\n' dialog|grep "install ok installed")

echo "$LOG_ZOO Checking for 'dialog' package: $DIALOG_PKG_OK"

if [ "" == "$DIALOG_PKG_OK" ]; then
	echo "$LOG_ZOO 'dialog' package not installed. Setting up 'dialog' package."
	sudo apt-get --force-yes --yes install dialog
fi

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

{

echo "$LOG_ZOO Package selection exit status:  $pkg_selection_status"

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

