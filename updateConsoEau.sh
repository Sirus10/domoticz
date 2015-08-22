#!/usr/bin/ksh
#######################################################################################
# This script will get the data from SDEI/SOGEST website and insert into domoticz.db
# Site    : http://domotique.web2diz.net/
# Detail  : http://domotique.web2diz.net/?p=131
# Source  : http://domotique.web2diz.net/files/updateConsoEau.sh.txt
# License : CC BY-SA 4.0
#
#  Usage:
#  ./updateConsoEau.sh [year] [month]
#
#######################################################################################
#
#  PART 0 Common variables
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


# SDEI PERSONAL CODE ( see http://domotique.web2diz.net/?p=137)
SDEI_CODE=              # put your code here      ex:  SDEI_CODE=PLOLKIKU
SDEI_EMAIL=             # put your email here     ex:  SDEI_EMAIL=toto@tata.com
SDEI_PASSWD=            # put your password here  ex:  SDEI_PASSWD=totolabrico42

# Set your provider comment/uncomment if needed (default = SDEI)
PROVIDER=SDEI
#PROVIDER=SOGEST
#PROVIDER=SENART

# Your virtual device ID in domoticz (see step2 here http://domotique.web2diz.net/?p=138 )
devicerowid=            #  put your devices idx here   ex : devicerowid=123

# Database file setup
dbfile=/home/pi/domoticz/domoticz.db


#######################################
#
#  PART 1 get the data
#
######################################
echo -e "\n - PART 1 Get the data from website for $dateY-$dateM"
if [[ $PROVIDER == 'SDEI' ]]
then
	loginpage="https://www.lyonnaise-des-eaux.fr/mon-compte-en-ligne/connexion/validation"
	datapage="https://www.lyonnaise-des-eaux.fr/mon-compte-en-ligne/statJData/$dateY/$dateM/$SDEI_CODE"
elif [[ $PROVIDER == 'SOGEST' ]]
then
	loginpage="https://www.sogest.info/mon-compte-en-ligne/connexion/validation"
	datapage="https://www.sogest.info/mon-compte-en-ligne/statJData/$dateY/$dateM/$SDEI_CODE"
elif [[ $PROVIDER == 'SENART' ]]
then
loginpage="https://www.eauxdesenart.com/mon-compte-en-ligne/connexion/validation"
datapage="https://www.eauxdesenart.com/mon-compte-en-ligne/statJData/$dateY/$dateM/$SDEI_CODE"	
fi


export_file=$workingDIR/$dateY-$dateM.dat

# This first cmd will allow to connect to the site and get the cookiefile
curl -s $loginpage -c $workingDIR/cookiefile -d "input_mail=$SDEI_EMAIL&input_password=$SDEI_PASSWD" > /dev/null
# This second cmd will download the data
curl -s $datapage -b $workingDIR/cookiefile > $export_file

echo -e "\n $export_file  generated "
# Remove cookiefiles
rm $workingDIR/cookiefile


#######################################
#
#
#  PART 2 set the file to be usable
#
######################################
echo -e "\n - PART 2 Update .dat file  "

sed -e 's/\\//g' $export_file > file1
sed -e 's/\],\[/\n/g' file1 > file2
sed -e 's/\[\[/\n/g' file2 > file3

sed -e 's/\"//g' file3  |grep -v ",0,0" |grep -e '^$' -v |grep -v ERR  > $export_file

rm file1 file2 file3
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

if [[ $val -eq 0 ]];
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
