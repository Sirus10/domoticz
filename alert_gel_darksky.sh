#!/bin/sh
# Changed to use DarkSky instead of UW
# Setup the city 
CITY=Paris
tempAler=3 # alert in case of lower temp than tempAler
APIKEY="put api key here"
recipient=ecoindre@gmail.com
sender="From: YourName <YourName@pi.com>"
LATLON="41.540970,1.96642"  # Update with the corrdinate you want

if [ "$1" != '' ] ; then
 CITY=$1 
fi

kill -9 `ps -ef | grep gel | grep -v grep |grep -v $$ | awk '{print $2}'`
# Download forecass for next days
curl -f "https://api.darksky.net/forecast/$APIKEY/$LATLON/?units=si" -o /tmp/weather.out


echo "############       Risque de gel      ###############"
echo "##########   "`date`"  ##########"

echo " Temp mini dans les jours a venir : "
tempsmini=`cat /tmp/weather.out  |sed -e 's/,/\n/g' |grep "temperatureMin" |grep -v "temperatureMinTime"|cut -d':' -f2|cut -d'.' -f1`




i=0
sentmail=0

for t in $tempsmini; do

	echo "Dans $i jour(s) : $t °C à $CITY"
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
	echo "Prevision à venir à $CITY (Minimales) <br> $val <br><center><small>Weather forecast from darksky.net</small></center>" | mail  -a "$sender"  -s "$(echo "$CITY : $SUB\nContent-Type: text/html")"  $recipient
fi
