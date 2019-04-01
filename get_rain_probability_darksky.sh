#/bin/sh
########################################################################################
#  This script will collect rain probability
#  for the next xx comming days 
#
# Site    : http://domotique.web2diz.net/
# Details : http://domotique.web2diz.net/probabilite-pluie-dans-domoticz/
# Source  : https://github.com/Sirus10/domoticz/blob/master/get_rain_probability_darksky.sh
# License : CC BY-SA 4.0
#
#  Usage:
#  get_rain_probability_darksky.sh
#
# Hourly scheduling in crontab : 
# 10 * * * *  /root/scripts/get_rain_probability_darksky.sh > /tmp/probal_rain.log
#
#######################################################################################
# SETUP START
LATLON="41.540970,0.796642"  
APIKEY="put your api key here" #see https://darksky.net/dev to get one for free
OUTPUT="/tmp/rain.out"
prefixurl="http://127.0.0.1:8080/json.htm?type=command&param=udevice&idx="
# SETUP END

# Just to be sure kill the previous run 
kill -9 `ps -ef | grep rain |grep -v vi| grep -v grep |grep -v $$ |grep -v tail | awk '{print $2}'`

# Download forecass for next 24h from api.darksky.net
curl -s "https://api.darksky.net/forecast/$APIKEY/$LATLON?lang=fr&exclude=currently,minutely,alerts,daily,flags" -o $OUTPUT


echo "####################   Propabilité Pluie ####################"
echo "All data for commin 24h: "
cat $OUTPUT |sed -e 's/\},/\n/g' |sed -e 's/\[/\n/g' |grep 'time'  | cut -d',' -f4-5 |head -25 |tail -24

echo "Selected data : "
idx=278 #       IDX
x=1     #       HEURE
proba_pluie=`cat $OUTPUT |sed -e 's/\},/\n/g' |sed -e 's/\[/\n/g' |grep 'time'  | cut -d',' -f5  | cut -d':' -f2 |awk NR==$x+1`
proba_pluie=`echo "$proba_pluie * 100" |bc`
intensite=`cat $OUTPUT |sed -e 's/\},/\n/g' |sed -e 's/\[/\n/g' |grep 'time'  | cut -d',' -f4  | cut -d':' -f2 |awk NR==$x+1`
echo Probal pluie dans $x h :  $proba_pluie % avec une intensité de $intensite mm / h.
url=`echo $prefixurl$idx"&nvalue=0&svalue="$proba_pluie|sed "s/ //"`
curl  $url -s > /dev/null

idx=277 #       IDX
x=5     #       HEURE
proba_pluie=`cat $OUTPUT |sed -e 's/\},/\n/g' |sed -e 's/\[/\n/g' |grep 'time'  | cut -d',' -f5  | cut -d':' -f2 |awk NR==$x+1`
proba_pluie=`echo "$proba_pluie * 100" |bc`
intensite=`cat $OUTPUT |sed -e 's/\},/\n/g' |sed -e 's/\[/\n/g' |grep 'time'  | cut -d',' -f4  | cut -d':' -f2 |awk NR==$x+1`
echo Probal pluie dans $x h :  $proba_pluie % avec une intensité de $intensite mm / h.
url=`echo $prefixurl$idx"&nvalue=0&svalue="$proba_pluie|sed "s/ //"`
curl  $url -s > /dev/null


idx=279 #       IDX
x=12    #       HEURE
proba_pluie=`cat $OUTPUT |sed -e 's/\},/\n/g' |sed -e 's/\[/\n/g' |grep 'time'  | cut -d',' -f5  | cut -d':' -f2 |awk NR==$x+1`
proba_pluie=`echo "$proba_pluie * 100" |bc`
intensite=`cat $OUTPUT |sed -e 's/\},/\n/g' |sed -e 's/\[/\n/g' |grep 'time'  | cut -d',' -f4  | cut -d':' -f2 |awk NR==$x+1`
echo Probal pluie dans $x h :  $proba_pluie % avec une intensité de $intensite mm / h.
url=`echo $prefixurl$idx"&nvalue=0&svalue="$proba_pluie|sed "s/ //"`
curl  $url -s > /dev/null


idx=280 #       IDX
x=24    #       HEURE
proba_pluie=`cat $OUTPUT |sed -e 's/\},/\n/g' |sed -e 's/\[/\n/g' |grep 'time'  | cut -d',' -f5  | cut -d':' -f2 |awk NR==$x+1`
proba_pluie=`echo "$proba_pluie * 100" |bc`
intensite=`cat $OUTPUT |sed -e 's/\},/\n/g' |sed -e 's/\[/\n/g' |grep 'time'  | cut -d',' -f4  | cut -d':' -f2 |awk NR==$x+1`
echo Probal pluie dans $x h :  $proba_pluie % avec une intensité de $intensite mm / h.
url=`echo $prefixurl$idx"&nvalue=0&svalue="$proba_pluie|sed "s/ //"`
curl  $url -s > /dev/null
