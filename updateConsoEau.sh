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
#
#######################################################################################
#
#  PART 0 Common variables and Conf file 
#
#######################################################################################
# Temp set global C local
LC_ALL=C

# Date setup (if not set = today)
if [ "$1" != '' ] && [ "$2" != '' ] && [[ "$1" == +([0-9]) ]] && [[ "$2" == +([0-9]) ]]
then
  dateY=$1
  dateM=$2
else
  dateY=`date "+%Y"`
  dateM=`date "+%m"`
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

# Configuration file check, it will create new one is not exist
if [ -s $workingDIR/setup_perso ]
then
echo -e "\n Using Configuration from file $workingDIR/setup_perso"
. $workingDIR/setup_perso
else 
echo "#######################################"
echo " NEED FOR CONFIG FILE CREATION  :      "
echo "#######################################"
echo "Personnal code counter number ( see http://domotique.web2diz.net/?p=137) "
read CODE
echo "Email adress :  "
read EMAIL
echo "Password   : "
read PASSWD
echo "Provider  (copy/paste) : "
echo "SDEI | SOGEST | SENART | SIEVA"
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
if [[ $PROVIDER == 'SDEI' ]]
then
        website="www.lyonnaise-des-eaux.fr"
elif [[ $PROVIDER == 'SOGEST' ]]
then
        website="www.sogest.info"
elif [[ $PROVIDER == 'SENART' ]]
then
        website="www.eauxdesenart.com"
elif [[ $PROVIDER == 'OLIVET' ]]
then
        website="www.eau-olivet.fr"
elif [[ $PROVIDER == 'SIEVA' ]]
then
        website="www.eau-en-ligne.com"
		loginpage="https://$website/security/signin"
		datapage="https://$website/ma-consommation/DetailConsoChart?year=$dateY&month=$dateM"
fi
# Special pages for eau-en-ligne.com
if [[ ! -n $loginpage ]] 
then 
loginpage="https://$website/mon-compte-en-ligne/connexion/validation"
datapage="https://$website/mon-compte-en-ligne/statJData/$dateY/$dateM/$SDEI_CODE"
fi

# This first cmd will allow to connect to the site and get the cookiefile
curl -s $loginpage -c $workingDIR/cookiefile -d "input_mail=$SDEI_EMAIL&input_password=$SDEI_PASSWD&signin[username]=$SDEI_EMAIL&signin[password]=$SDEI_PASSWD&" > /dev/null
# This second cmd will download the data
curl -s $datapage -b $workingDIR/cookiefile > $export_file

echo -e "\n $export_file  generated "
# Remove cookiefiles
rm $workingDIR/cookiefile


#######################################
#
#  PART 2 set the file to be usable
#
######################################
echo -e "\n - PART 2 Update .dat file  "

sed -e 's/\\//g'  -e 's/\],\[/\n/g' -e 's/\[\[/\n/g' -e 's/\]\]/\n/g'  $export_file > filetmp
sed -e 's/\"//g' filetmp |grep -v ",0,0" |grep -e '^$' -v |grep -v ERR  > $export_file

rm filetmp
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

echo  "DELETE FROM \`Meter_Calendar\` WHERE devicerowid=$devicerowid and date = '$yy-$mm-$dd'; INSERT INTO \`Meter_Calendar\` VALUES ('$devicerowid'," \'$val1\', \'$val2\', \'$yy-$mm-$dd\' ");" >> $sqltmpfile

done < $export_file

# GENERATE SQL FOR UPDATE DEVICE STATUS
DEVICESTATUS1="update DeviceStatus set lastupdate = '$yy-$mm-$dd $hh' where id = $devicerowid;"


###  prepare  and compare fromm previous run  ####

comm -3 $sqltmpfile $sqlpreviousfile > $sqlfinalfile
cat $sqlfinalfile

echo $DEVICESTATUS1
mv $sqltmpfile $sqlpreviousfile



#######################################
#
#  PART 4 Update the db
#
######################################
#exit

echo -e "\n - PART 4 Update the db  "

if [ -s $sqlfinalfile ]
then
   echo -e "\nFile size is NOT zero ->  DB update needed"
   echo " Stoping Domoticz ! "
   sudo /etc/init.d/domoticz.sh stop
   echo " Domoticz stopped"
        echo Update DB START

        echo Update Values
        sudo cat $sqlfinalfile |sqlite3  $dbfile

        echo Update Status
        sudo echo $DEVICESTATUS1 |sqlite3  $dbfile

        echo Update DB END
    echo " Starting Domoticz !"
    sudo /etc/init.d/domoticz.sh start
    echo " Domoticz started "
else
   echo -e "\nFile size is zero -> DB update NOT needed"
fi


echo -e "\n ### END ###\n"
