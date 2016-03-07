#
# Simple cleanup and rotate logs script for domoticz
# Ref : http://domotique.web2diz.net/?p=577
#
DATE_FORMAT=`date +%u`

echo  "############### Start Script ###############" `date`

echo "cp /home/pi/domoticz/logs/domoticz.log /home/pi/domoticz/logs/domoticz.log.$DATE_FORMAT"
sudo cp /home/pi/domoticz/logs/domoticz.log /home/pi/domoticz/logs/domoticz.log.$DATE_FORMAT

echo "cleanup log /home/pi/domoticz/logs/domoticz.log"
sudo chmod 777 /home/pi/domoticz/logs/domoticz.log
echo "############### RESTART LOGS `date` ###############" > /home/pi/domoticz/logs/domoticz.log

echo  "############### Ends Script  ###############" `date`
