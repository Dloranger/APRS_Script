#!/bin/bash

################################################################################
# DEFINE FUNCTIONS
################################################################################


		
function check_root {
	if [[ $EUID -ne 0 ]]; then
		echo "--------------------------------------------------------------"
		echo " This script must be run as root...ABORTING!"
		echo "--------------------------------------------------------------"
		exit 1
	else
		echo "--------------------------------------------------------------"
		echo " Looks like you are running as root...Continuing!"
		echo "--------------------------------------------------------------"
	fi	
}

################################################################################

function check_internet {
	wget -q --spider http://google.com
	
	if [ $? -eq 0 ]; then
		echo "--------------------------------------------------------------"
		echo " INTERNET CONNECTION REQUIRED: Connection Found...Continuing!"
		echo "--------------------------------------------------------------"
	else
		echo "--------------------------------------------------------------"
		echo " INTERNET CONNECTION REQUIRED: Not Connection...Aborting!"
		echo "--------------------------------------------------------------"
		exit 1
	fi
}

################################################################################

function check_os {
	# Detects ARM processor
	if (cat < /proc/cpuinfo | grep ARM > /dev/null) ; then
		PROCESSOR="ARM"
	else
		PROCESSOR="UNSUPPORTED"
	fi
	
	# Detects Debian Version
	if (grep -q "$REQUIRED_OS_VER." /etc/debian_version) ; then
		DEBIAN_VERSION="$REQUIRED_OS_VER"
	else
		DEBIAN_VERSION="UNSUPPORTED"
	fi

	# Abort if there is a mismatch
	if [ "$PROCESSOR" != "ARM" ] || [ "$DEBIAN_VERSION" != "$REQUIRED_OS_VER" ] ; then
		echo
		echo "**** ERROR ****"
		echo "This script will only work on Debian $REQUIRED_OS_VER ($REQUIRED_OS_NAME) images at this time."
		echo "No other version of Debian is supported at this time. "
		echo "**** EXITING ****"
		exit -1
	fi
}

################################################################################

function check_filesystem {
	PARTITION_SIZE=$(df -m | awk '$1=="/dev/root"{print$2}')
	
	if [ $PARTITION_SIZE -ge $MIN_PARTITION_SIZE ]; then
		# Partition is large enough
		echo "--------------------------------------------------------------"
		echo " Partition Size Looks Good...Continuing!"
		echo "--------------------------------------------------------------"
	else
		# Partition is too small. Show Message
		menu_expand_file_system $MIN_DISK_SIZE
	fi
}

################################################################################

function check_network {
	# Get Eth0 IP for later display
	IP_ADDRESS=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1);
}

################################################################################

function wait_for_network {
	echo "--------------------------------------------------------------"
	echo " Waiting for network/internet connection"
	echo "--------------------------------------------------------------"
	
	# Verify network is still up for building over wifi
	echo "Verifying network/internet is still available, please wait..."
	while !(wget -q --spider http://google.com >> /dev/null); do
		echo "Network is down.  Waiting 5 seconds for the network to reconnect..."
		sleep 5s
	done
	echo "Network connected.  Proceeding..."
}

################################################################################

function set_hostname () {
	### SET HOSTNAME ###
	echo "--------------------------------------------------------------"
	echo " Setting Hostname to $1"
	echo "--------------------------------------------------------------"

	sudo hostnamectl set-hostname "$1"
}

function enable_i2c {
	echo "--------------------------------------------------------------"
	echo " Enable I2C bus and I2C Devices"
	echo "--------------------------------------------------------------"

	apt-get install --assume-yes --fix-missing i2c-tools

	sed -i /boot/config.txt -e "s#\#dtparam=i2c_arm=on#dtparam=i2c_arm=on#"
	echo "i2c-dev" >> /etc/modules
}
################################################################################

function config_ics_controllers {
	echo "--------------------------------------------------------------"
	echo " Enable ICS Controller intergrations"
	echo "--------------------------------------------------------------"

	cat >> /boot/config.txt <<- DELIM
		#Enable FE-Pi Overlay
		dtoverlay=fe-pi-audio
		dtoverlay=i2s-mmap
		#Enable mcp23s17 Overlay
		dtoverlay=mcp23017,addr=0x20,gpiopin=12
		
		#Enable mcp3008 adc overlay
		dtoverlay=mcp3008:spi0-0-present,spi0-0-speed=3600000
		# Enable UART for serial console
		enable_uart=1
		DELIM
}

function pause {
	read -p "Press [Enter] key to start backup..."
}
