#!/usr/bin/ksh
#######################################################################################
# This script will get the data for previous mounth 
# from SDEI/SOGEST website and insert into domoticz.db
# It requiere updateConsoEau.sh to be setup.
# Site    : http://domotique.web2diz.net/
# Detail  : http://domotique.web2diz.net/?p=131
# Source  : https://github.com/Sirus10/domoticz/blob/master/updateConsoEau_M-1.sh
# License : CC BY-SA 4.0
#
#  Usage:
#  ./updateConsoEau_M-1.sh
#
#######################################################################################
#
#  PART 0 Common variables
#
#######################################################################################

dateY=`date '+%Y' --date '1 month ago'`
dateM=`date '+%m' --date '1 month ago'`

echo date : $dateY $dateM
#######################################################################################
#
#  PART 1 Run the main script with the M-1 variables
#
#######################################################################################

/home/pi/EAU/updateConsoEau.sh $dateY $dateM
