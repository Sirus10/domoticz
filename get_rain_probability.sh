#!/usr/bin/ksh
#######################################################################################
# This script will get weather date from wunderground API and then add the
# propability of rain into domoticz % devices.
# Site    : http://domotique.web2diz.net/
# Source  : https://github.com/Sirus10/domoticz/blob/master/get_rain_probability.sh
# License : CC BY-SA 4.0
#
#  Usage:
#  ./get_rain_probability.sh
#
#######################################################################################
# Setup START
COUNTRY=FRANCE
APIKEY=  # put your api key here
TOWN=PARIS    # put your town here 
IDX_1h=144    # Update according to your domoticz % divices
IDX_5h=153    # Update according to your domoticz % divices
IDX_12h=189   # Update according to your domoticz % divices
IDX_24h=190   # Update according to your domoticz % divices

DOMO_HTTP=192.168.1.16:8080
# Setup END

curl -f "http://api.wunderground.com/api/$APIKEY/hourly/lang:FR/q/France/$TOWN.xml" -o /tmp/weather$TOWN.out

x=1 # Hour
proba_rain=`grep "pop" /tmp/weather$TOWN.out | sed "s/<pop>// "|sed "s/<\/pop>//" |awk 'NR==1' `
echo Proba Rain in $x h :  $proba_rain %
url="http://$DOMO_HTTP/json.htm?type=command&param=udevice&idx=$IDX_1h&nvalue=0&svalue="$proba_rain

url=`echo $url |sed "s/ //"`
echo $url
curl -f $url

x=5 # Hour
proba_rain=`grep "pop" /tmp/weather$TOWN.out | sed "s/<pop>// "|sed "s/<\/pop>//" |awk 'NR==5' `
echo Proba Rain in $x h :  $proba_rain %
url="http://$DOMO_HTTP/json.htm?type=command&param=udevice&idx=$IDX_5h&nvalue=0&svalue="$proba_rain

url=`echo $url |sed "s/ //"`
echo $url
curl -f $url

x=12 # Hour
proba_rain=`grep "pop" /tmp/weather$TOWN.out | sed "s/<pop>// "|sed "s/<\/pop>//" |awk 'NR==12' `
echo Probal Rain in $x h :  $proba_rain %
url="http://$DOMO_HTTP/json.htm?type=command&param=udevice&idx=$IDX_12h&nvalue=0&svalue="$proba_rain

url=`echo $url |sed "s/ //"`
echo $url
curl -f $url

x=24 # Hour
proba_rain=`grep "pop" /tmp/weather$TOWN.out | sed "s/<pop>// "|sed "s/<\/pop>//" |awk 'NR==24' `
echo Probal pluie dans $x h :  $proba_rain %
url="http://$DOMO_HTTP/json.htm?type=command&param=udevice&idx=$IDX_24h&nvalue=0&svalue="$proba_rain

url=`echo $url |sed "s/ //"`
echo $url
curl -f $url
