#!/bin/bash

# This bash script will prepare your system for use as a APRS 
# igate/Digipeater node.  The process is derived from the walk
# through created by N1AAE.  
# https://n1aae.com/raspberry-pi-aprs-direwolf-linux-igate-digipeater/
# Dan, KG7PAR has taked the process and made it into this self 
# executing script with adaptations for it to be used with the 
# "PI-REPEATER-1X" radio hardware interface boards.
#
# If you need your aprs password, go here
# http://apps.magicbug.co.uk/passcode/

#Find YOUR Lat/Long
# https://www.findlatitudeandlongitude.com/
source "./functions/functions.sh"

echo "--------------------------------------------------------------"
echo " Variables establishment"
echo "--------------------------------------------------------------"
iGate="1"
Digipeater="1"
Callsign="KG7PAR"
APRS_PASSWORD="20135"
LATITUDE="47.97"
LONGITUDE="-122.14"
APRS_SSID="10"
#-0 Your primary station usually fixed and message capable
#-1 generic additional station, digi, mobile, wx, etc
#-2 generic additional station, digi, mobile, wx, etc
#-3 generic additional station, digi, mobile, wx, etc
#-4 generic additional station, digi, mobile, wx, etc
#-5 Other networks (Dstar, Iphones, Androids, Blackberry's etc)
#-6 Special activity, Satellite ops, camping or 6 meters, etc
#-7 walkie talkies, HT's or other human portable
#-8 boats, sailboats, RV's or second main mobile
#-9 Primary Mobile (usually message capable)
#-10 internet, Igates, echolink, winlink, AVRS, APRN, etc
#-11 balloons, aircraft, spacecraft, etc
#-12 APRStt, DTMF, RFID, devices, one-way trackers*, etc
#-13 Weather stations
#-14 Truckers or generally full time drivers
PLUGHW="plughw:1,0"
REQUIRED_OS_VER="9"
REQUIRED_OS_NAME="Stretch"
MIN_PARTITION_SIZE="3000"
MIN_DISK_SIZE="4GB"
HOSTNAME="APRS_$Callsign""_""$APRS_SSID"
echo $HOSTNAME


### INITIAL FUNCTIONS ####
check_root
check_os
check_filesystem
check_network
check_internet
set_hostname $HOSTNAME

echo "--------------------------------------------------------------"
echo " Perform Raspbian Upgrades"
echo "--------------------------------------------------------------"

apt-get update -y
apt-get dist-upgrade -y
rpi-update -y


echo "--------------------------------------------------------------"
echo " Installing Dependencies"
echo "--------------------------------------------------------------"

apt-get install --assume-yes --fix-missing git-all libasound2-dev i2c-tools \
	alsa-base alsa-utils


echo "--------------------------------------------------------------"
echo " Enabling ICS Controller intergrations"
echo "--------------------------------------------------------------"
enable_i2c
config_ics_controllers


echo "--------------------------------------------------------------"
echo " Remove Pulse Audio"
echo "--------------------------------------------------------------"

apt-get remove --purge pulseaudio
apt-get autoremove
rm -rf /home/pi/.pulse


echo "--------------------------------------------------------------"
echo " Install Direwolf"
echo "--------------------------------------------------------------"

apt-get install direwolf -y

echo "--------------------------------------------------------------"
echo " Configure Direwolf"
echo "--------------------------------------------------------------"

cd ~
cd ./direwolf
sed -i /root/direwolf/direwolf.conf -e "s#\# ADEVICE  plughw:1,0#ADEVICE $PLUGHW#"
#sed -i /root/direwolf/direwolf.conf -e "s#\# ADEVICE  plughw:1,0#ADEVICE plughw:1,0#"
sed -i /root/direwolf/direwolf.conf -e "s#MYCALL N0CALL#MYCALL $Callsign""-$APRS_SSID#"
#sed -i /root/direwolf/direwolf.conf -e "s#MYCALL N0CALL#MYCALL kg7par""-10#"


echo "--------------------------------------------------------------"
echo " Configure Direwolf - digipeater"
echo "--------------------------------------------------------------"

if [ $DIGIPEAT  = "1" ] then
	sed -i /root/direwolf/direwolf.conf -e "s#\#DIGIPEAT 0 0#DIGIPEAT 0 0#"
fi


echo "--------------------------------------------------------------"
echo " Configure Direwolf - igate"
echo "--------------------------------------------------------------"

if [ $Igates = "1" ] then
	sed -i /root/direwolf/direwolf.conf -e "s#\#IGSERVER noam.aprs2.net#IGSERVER noam.aprs2.net#"
	#noam.aprs2.net – for North America
	#soam.aprs2.net – for South America
	#euro.aprs2.net – for Europe and Africa
	#asia.aprs2.net – for Asia
	#aunz.aprs2.net – for Oceania
fi


echo "--------------------------------------------------------------"
echo " Configure Direwolf - aprs credentials"
echo "--------------------------------------------------------------"
# Enter APRS login and password
sed -i /root/direwolf/direwolf.conf -e "s#\#IGLOGIN WB2OSZ-5 123456#IGLOGIN $Callsign-$APRS_SSID $APRS_PASSWORD#"
sed -i /root/direwolf/direwolf.conf -e "s#\#IGLOGIN WB2OSZ-5 123456#IGLOGIN kg7par-10 20135#"


# TODO: Scrape https://ipinfo.io/ or similar for long/lat info or get from a GPS source
echo "--------------------------------------------------------------"
echo " Configure Direwolf - beacon"
echo "--------------------------------------------------------------"
sed -i /root/direwolf/direwolf.conf "s#\#PBEACON sendto=IG delay=0:30 every=60:00 symbol=\"igate\" overlay=T lat=42^37.14N long=071^20.83W#PBEACON sendto=IG delay=0:30 every=60:00 symbol=\"igate\" overlay=T lat=$LATITUDE long=$LONGITUDE#"


echo "--------------------------------------------------------------"
echo " Configure Direwolf - repeat network data"
echo "--------------------------------------------------------------"
sed -i /root/direwolf/direwolf.conf -e "s#\#IGTXVIA 0 WIDE1-1#IGTXVIA 0 WIDE1-1#"


echo "--------------------------------------------------------------"
echo " Configure Direwolf completed"
echo "--------------------------------------------------------------"


