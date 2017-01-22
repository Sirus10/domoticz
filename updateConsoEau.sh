#!/usr/bin/ksh
#######################################################################################
# This script will get the data from SDEI/SOGEST website and insert into domoticz.db
# Site    : http://domotique.web2diz.net/
# Detail  : http://domotique.web2diz.net/?p=131
# List of working provider : http://domotique.web2diz.net/?p=320
# Source  : https://github.com/Sirus10/domoticz/blob/master/updateConsoEau.sh
# License : CC BY-SA 4.0
#
#  Usage:
#  ./updateConsoEau.sh [year] [month]
#  Debug:
#  ./updateConsoEau.sh DEBUG
#
#######################################################################################
#
#  PART 0 Common variables and Conf file 
#
#######################################################################################
# Temp set global C local
LC_ALL=C
DEBUG=FALSE
ERRORMSG="try to run with ./updateConsoEau.sh DEBUG"

# Date setup (if not set = today)
if [ "$1" != '' ] && [ "$2" != '' ] && [[ "$1" == +([0-9]) ]] && [[ "$2" == +([0-9]) ]]
then
  dateY=$1
  dateM=$2
else
  dateY=`date "+%Y"`
  dateM=`date "+%m"`
fi

if [[ "$1" == 'DEBUG' ]] then
 DEBUG=true 
fi
if [[ "$DEBUG" == 'true' ]] then
 echo -e "\n  START DEBUG MODE \n"
fi

# SQL Files setup for temporary and final file
workingDIR=/home/pi/EAU
sqlfinalfile=$workingDIR/only_new_generated.$dateY-$dateM.sql
sqlpreviousfile=$workingDIR/previous.generated.$dateY-$dateM.sql
sqltmpfile=$workingDIR/temps.generated.$dateY-$dateM.sql
# Database file setup
dbfile=/home/pi/domoticz/domoticz.db
# Export file :
export_file=$workingDIR/$dateY-$dateM.dat
filetmp=$workingDIR/filetmp

# Configuration file check, it will create new one is not exist
if [ -s $workingDIR/setup_perso ]
	then
	echo -e "\n Using Configuration from file $workingDIR/setup_perso"
	. $workingDIR/setup_perso
	else 
	echo "#######################################"
	echo " NEED FOR CONFIG FILE CREATION  :      "
	echo "#######################################"
	echo "Personnal counter number ( see http://domotique.web2diz.net/?p=137) "
	read CODE
	echo "Email adress :  "
	read EMAIL
	echo "Password   : "
	read PASSWD
	echo "Provider  (copy/paste) : "
	echo "SUEZ | SDEI | SOGEST | SEERC | SOBEP | EEF | SENART | OLIVET | SIEVA | SEE"
	read PROVIDER
	echo "Your virtual device ID in domoticz (see step2 here http://domotique.web2diz.net/?p=138 ) "
	read devicerowid
	echo "SDEI_CODE=$CODE
	SDEI_EMAIL=$EMAIL
	SDEI_PASSWD=$PASSWD
	PROVIDER=$PROVIDER
	devicerowid=$devicerowid" > $workingDIR/setup_perso
	echo "#######################################"
	echo " CONFIG FILE setup_perso CREATED WITH : "
	echo "#######################################"
	cat $workingDIR/setup_perso
	echo "#######################################"
	. $workingDIR/setup_perso
fi


#######################################
#
#  PART 1 get the data
#
######################################
echo -e "\n - PART 1 Get the data from website for $dateY-$dateM"

if   [[ $PROVIDER == 'SDEI' ]]		then website="www.toutsurmoneau.fr"
elif [[ $PROVIDER == 'SOGEST' ]]	then website="www.toutsurmoneau.fr"
elif [[ $PROVIDER == 'SEERC' ]]		then website="www.toutsurmoneau.fr"
elif [[ $PROVIDER == 'SOBEP' ]]		then website="www.toutsurmoneau.fr"
elif [[ $PROVIDER == 'EEF' ]]		then website="www.toutsurmoneau.fr"
elif [[ $PROVIDER == 'SUEZ' ]]		then website="www.toutsurmoneau.fr"
elif [[ $PROVIDER == 'SENART' ]]	then website="www.eauxdesenart.com"
elif [[ $PROVIDER == 'OLIVET' ]] 	then website="www.eau-olivet.fr"
elif [[ $PROVIDER == 'SIEVA' ]] 	then website="www.eau-en-ligne.com"
elif [[ $PROVIDER == 'SEE' ]] 		then website="www.eauxdelessonne.com"
fi

# Special pages for eau-en-ligne.com
if [[ ! -n $loginpage ]] 
then 
loginpage="https://$website/mon-compte-en-ligne/je-me-connecte"
datapage="https://$website/mon-compte-en-ligne/statJData/$dateY/$dateM/$SDEI_CODE"
fi


if [[ "$DEBUG" == 'true' ]] then 
	echo "########## debug URL START   ###############"
	echo login page 	: $loginpage
	echo datapage page  : $datapage
	echo "########## debug URL END     ###############"
fi


#############  1 GET THE TOKEN   #################
agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.112 Safari/534.30" 
csrftoken=`curl -c $workingDIR/cookiefile -b $workingDIR/cookiefile  $loginpage  -A "$agent"  -s |grep _csrf_toke | head -1 | cut -d'"' -f6`
if [[ "$DEBUG" == 'true' ]] then 
	echo "########## debug csrftoken START ###############"
	echo csrftoken : 
	echo $csrftoken
	echo "########## debug csrftoken END   ###############"
fi
if [[  -n $csrftoken ]] then 
	echo "  - TOKEN OK" 
else 
	echo "  - TOKEN NOT OK !! $ERRORMSG" 
fi

#############  2 LOGIN   #################
curl -L $loginpage -A "$agent" -s \
-c $workingDIR/cookiefile \
-b $workingDIR/cookiefile \
-d "_username=$SDEI_EMAIL&_password=$SDEI_PASSWD&_csrf_token=$csrftoken&signin[username]=$SDEI_EMAIL&signin[password]" |grep "Connexion en cours" > /dev/nul
if [[ "$?" == "0" ]] then
 echo "  - LOGIN OK" 
else 
# echo "  - LOGIN NOT OK !! $ERRORMSG" 
fi

#############  3 GET DATA  #################
curl -s $datapage -b $workingDIR/cookiefile > $export_file
CR=$?
if [[ "$DEBUG" == 'true' ]] then 
	echo "########## debug export_file START ###############"
	cat $export_file
	echo "########## debug export_file END   ###############"
fi 
if [[ -s $export_file ]] then 
	echo "  - DATA collection OK" 
	echo -e "\n $export_file  generated "
else 
	echo " Error not able to get data !! $ERRORMSG" 
fi

#Remove cooki file 
rm $workingDIR/cookiefile


#######################################
#
#  PART 2 set the file to be usable
#
######################################
echo -e "\n - PART 2 Update .dat file  "
sed -e 's/\\//g'  -e 's/\],\[/\n/g' -e 's/\[\[/\n/g' -e 's/\]\]/\n/g'  $export_file  > $filetmp
sed -e 's/\"//g' $filetmp |grep -v ",0,0" |grep -e '^$' -v |grep -v ERR  > $export_file

if [[ "$DEBUG" == 'true' ]] then 
	echo "########## debug .dat file START ###############"
	cat $export_file
	echo "########## debug .dat file END   ###############"
fi 
echo -e "\n $export_file  Updated "

#######################################
#
#  PART 3 Generate SQL
#
######################################
echo -e "\n - PART 3 Generate SQL"

# create the previous file is does not exits
if [ ! -f "$sqlpreviousfile" ] ; then touch $sqlpreviousfile ; fi
IFS=,
while read date val val2 ; do

	#### DATE ####
	 dd=`echo $date |awk -F/ '{print $1}'`
	 mm=`echo $date |awk -F/ '{print $2}'`
	 yy=`echo $date |awk -F/ '{print $3}'`
	 hh=`date +%H:%M:%S`
	#### VAL1  ####

	val1=$(( $val * 100))
	if [[ $val -eq 0 ]] && [[ ! -z "$prevVal2" ]];
	then
			  float val1=$((100 * ($val2-$prevVal2)))
	fi
	prevVal2=$val2
	### Generation  ###
	echo  "DELETE FROM \`Meter_Calendar\` WHERE devicerowid=$devicerowid and date = '$yy-$mm-$dd'; INSERT INTO \`Meter_Calendar\` (DeviceRowID,Value,Counter,Date) VALUES ('$devicerowid'," \'$val1\', \'$val2\', \'$yy-$mm-$dd\' "); " >> $sqltmpfile

done < $export_file

if [[ "$DEBUG" == 'true' ]] then 
	echo "########## debug SQL file START ###############"
	cat $sqltmpfile
	echo "########## debug SQL file END   ###############"
fi

# GENERATE SQL FOR UPDATE DEVICE STATUS
DEVICESTATUS1="update DeviceStatus set lastupdate = '$yy-$mm-$dd $hh' where id = $devicerowid;"


###  prepare  and compare fromm previous run  ####

comm -3 $sqltmpfile $sqlpreviousfile > $sqlfinalfile
if [[ "$DEBUG" == 'true' ]] then 
	echo "########## debug sqlfinalfile file START ###############"
	cat $sqlfinalfile
	echo $DEVICESTATUS1
	echo "########## debug sqlfinalfile file END   ###############"
fi


mv $sqltmpfile $sqlpreviousfile

echo -e "\nSQL with "`wc -l  $sqlfinalfile |awk ' {print $1}`" line(s) generated : $sqlfinalfile"



#######################################
#
#  PART 4 Update the db
#
######################################


echo -e "\n - PART 4 Update the db  "

if [ -s $sqlfinalfile ]
then
   echo -e "\nFile size is NOT zero ->  DB update needed"
   echo " Stoping Domoticz ! "
   sudo /etc/init.d/domoticz.sh stop
   echo " Domoticz stopped"
        echo " Update DB START"

        echo "   Update Values"
        sudo cat $sqlfinalfile |sqlite3  $dbfile

        echo "   Update Status"
        sudo echo $DEVICESTATUS1 |sqlite3  $dbfile

        echo " Update DB END \n "
    echo " Starting Domoticz !"
    sudo /etc/init.d/domoticz.sh start
    echo " Domoticz started "
else
   echo -e "\nFile size is zero -> DB update NOT needed"
fi


echo -e "\n ### END ###\n"
