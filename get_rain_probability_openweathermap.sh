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
# 10 * * * *  /root/scripts/get_rain_probability_openweathermap.sh > /tmp/probal_rain.log
#
#######################################################################################
# SETUP START
LATL="41.540970"
LON="0.796642"
APIKEY="put your api key here" #see https://home.openweathermap.org/api_keys to get one for free
units=metric
OUTPUT="/tmp/rain.out"
prefixurl="http://127.0.0.1:8080/json.htm?type=command&param=udevice&idx="
# SETUP END

# Just to be sure kill the previous run 
kill -9 `ps -ef | grep rain |grep -v vi| grep -v grep |grep -v $$ |grep -v tail | awk '{print $2}'`

# Download forecass for next 24h from api.openweathermap.org
curl -s "https://api.openweathermap.org/data/2.5/forecast?lat=$LAT&lon=$LON&appid=$APIKEY&units=$units" -o $OUTPUT


#Merci ChatGPT pour l'aide dans les lignes suivante...
# Récupérer l'heure actuelle en format timestamp 
current_timestamp=$(date +%s)
# Heure dans 1h
timestamp_in_1h=$((current_timestamp + 3600))
value_in_1h=$(cat $OUTPUT | grep -oE '"dt":[0-9]+' | cut -d':' -f2 | awk -v ts=$timestamp_in_1h 'NR==1{closest=$1; diff=ts-$1; if(diff<0) diff=-diff;} diff<=(ts-closest){closest=$1; diff=ts-$1; if(diff<0) diff=-diff;} END{print closest}')
# Heure dans 5h
timestamp_in_5h=$((current_timestamp + 5 * 3600))
value_in_5h=$(cat $OUTPUT | grep -oE '"dt":[0-9]+' | cut -d':' -f2 | awk -v ts=$timestamp_in_5h 'NR==1{closest=$1; diff=ts-$1; if(diff<0) diff=-diff;} diff<=(ts-closest){closest=$1; diff=ts-$1; if(diff<0) diff=-diff;} END{print closest}')
# Heure dans 12h
timestamp_in_12h=$((current_timestamp + 12 * 3600))
value_in_12h=$(cat $OUTPUT | grep -oE '"dt":[0-9]+' | cut -d':' -f2 | awk -v ts=$timestamp_in_12h 'NR==1{closest=$1; diff=ts-$1; if(diff<0) diff=-diff;} diff<=(ts-closest){closest=$1; diff=ts-$1; if(diff<0) diff=-diff;} END{print closest}')
# Heure dans 24h
timestamp_in_24h=$((current_timestamp + 24 * 3600))
value_in_24h=$(cat $OUTPUT | grep -oE '"dt":[0-9]+' | cut -d':' -f2 | awk -v ts=$timestamp_in_24h 'NR==1{closest=$1; diff=ts-$1; if(diff<0) diff=-diff;} diff<=(ts-closest){closest=$1; diff=ts-$1; if(diff<0) diff=-diff;} END{print closest}')

tableau_pluie=$(cat $OUTPUT | jq -r '.list[] | "\(.dt) \(.pop) \(.rain)"')

while IFS= read -r line; do
    dt=$(echo $line | awk '{print $1}')					# UTC time zone 
    pop=$(echo $line | awk '{print $2}')				# Probability of precipitation 
	pop=`echo "$pop * 100" |bc`
    rain=$(echo $line | awk '{print $3}')				# Precipitation volume, mm
	rain=$(echo "$rain" | jq '.["3h"]')
	rain=$(echo "$rain/3" | bc -l)						          # Valleur sur 3h à diviser # A confirmer
	rain=$(echo "$rain" | awk '{printf "%.2f", $0}')  	# Arrondir à 2 décimales

for hours in 1 5 12 24; do
    case $hours in
        1)	value=$value_in_1h  && idx=278	;;  # Entreer vos idx ici
        5)	value=$value_in_5h  && idx=277	;;
        12)	value=$value_in_12h && idx=279	;;
        24)	value=$value_in_24h && idx=280	;;
		*) echo "Valeur non prise en charge : $hours" && exit 1  ;;
    esac
    
    if [ "$dt" -eq "$value" ]; then
        # echo "idx : $idx, dt: $dt, pop: $pop, rain: $rain, hours: $hours"
		echo Probal pluie dans $hours h :  $pop % avec une intensité de $rain mm / h.
		url=`echo $prefixurl$idx"&nvalue=0&svalue="$pop|sed "s/ //"`
		curl  $url -s > /dev/null
    fi
done

done <<< "$tableau_pluie"

exit 0
