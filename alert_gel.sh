#!/bin/sh
#
########################################################################################
#  This script aim will alert by mail if temperature
#  will be lower than x °C in the comming days 
#
# Site    : http://domotique.web2diz.net/
# Details : http://domotique.web2diz.net/?p=859
# Source  : https://github.com/Sirus10/domoticz/blob/master/get_rain_probability.sh
# License : CC BY-SA 4.0
#
#  Usage:
#  ./alert_get <city>
# EX : ./alert_gel Montpellier
#
# Daily scheduling in crontab : 
# 30 7 * * *  /root/scripts/gel.sh Toulouse > /tmp/probal_gelCaraman.log
#
#######################################################################################
# Setup the default city, 
CITY=Toulouse  # Default city is $1 not set
# Alert in case of lower temp than tempAler.
# If you wahtn be alerte if tempterature lwill be lower than 3° set : tempAler=3
tempAler=3 
APIKEY=your_wunderground_apiKEY
recipient=youremail@mail.com
sender="From: Manu <sender@pi3.com>"

if [ "$1" != '' ] ; then
 CITY=$1
fi

kill -9 `ps -ef | grep prevision | grep -v grep |grep -v $$ | awk '{print $2}'`
# Download forecass for next 10 days
curl -f "http://api.wunderground.com/api/$APIKEY/forecast10day/lang:FR/q/France/"$CITY".xml" -o /tmp/weather$CITY-10D.out


echo "############       Risque de gel      ###############"
echo "##########   "`date`"  ##########"

echo " Temp mini dans les 10 jours a venir : "
tempsmini=`/usr/local/bin/xml_grep  'low/celsius' /tmp/weather$CITY-10D.out --text_only`
i=0
sentmail=0

for t in $tempsmini; do
        echo "Dans $i jour(s) : $t  °C  à $CITY"
        #val=$val"Dans $i jours : $t °C <br>\n"
        if [ $t -lt 3 ]
        then
                echo "--------------------------->   Risque de gel dans $i jour(s) ! "
                alert=" -->  <b> Risque de gel dans $i jours ! </b>"
                if [ $sentmail  -eq 0  ]
                then
                        MESS="Risque de Gel Dans $i jours : $t °C à $CITY"
                        SUB="Risque de Gel dans $i jours"
                        SUB=`echo $SUB |sed 's/0 jours/les 24h/g'`
                        SUB=`echo $SUB |sed 's/1 jours/1 jour/g'`
                        sentmail=1
                fi
        else
        alert=""
        fi
        val=$val"Dans $i jours: $t °C "$alert"<br>"

i=$(($i + 1))
done
val=`echo $val |sed 's/0 jours/les 24h/g'`
val=`echo $val |sed 's/1 jours/1 jour/g'`

echo "#####################################"
echo $val
echo "#####################################"

# Envois du mail si besoin
if [ $sentmail  -eq 1  ]
then
        echo "Envoi du mail d'alerte "
        echo "Prevision à venir à $CITY (Minimales) <br> $val <br><center><small>Weather forecast from wunderground.com</small></center>" | mail  -a "$sender"  -s "$(echo "$CITY : $SUB\nContent-Type: text/html")"  $recipient
fi

