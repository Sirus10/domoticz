/******************************************
# This script aim at reporting tack water level
#      using jsn-sr04t sensor
# Site    : https://domotique.web2diz.net/
# Detail  : https://domotique.web2diz.net/?p=904
#
# License : CC BY-SA 4.0
#
# This script use the x10rf library 
# See source here : 
# https://github.com/p2baron/x10rf
#
#
/*******************************************/
//Define Trig and Echo pin
// including x10rf and sleep library 
#include <x10rf.h>
#include <avr/sleep.h>
#include <avr/wdt.h>
#define trigPin 2
#define echoPin 1
#define rfout 4
//Define variables
long duration;
int distance;



#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif
volatile boolean f_wdt = 1;

// RF SETUP
x10rf myx10 = x10rf(rfout,0,5);
void setup()
{
  ADCSRA &= ~(1<<ADEN);// disable ADC (before power-off)
myx10.begin();
//Define inputs and outputs
pinMode(trigPin, OUTPUT);
pinMode(echoPin, INPUT);
setup_watchdog(9); // approximately 8 seconds sleep 

}
void loop()
{
//Clear the trigPin by setting it LOW
digitalWrite(trigPin, LOW);
delayMicroseconds(5);
//Trigger the sensor by setting the trigPin high for 10 microseconds
digitalWrite(trigPin, HIGH);
delayMicroseconds(10);
digitalWrite(trigPin, LOW);
//Read the echoPin. pulseIn() returns the duration (length of the pulse) in microseconds.
duration = pulseIn(echoPin, HIGH);
// Calculate the distance
distance= duration*0.034/2;
//Print the distance on the Serial Monitor 
myx10.RFXsensor(4,'t','T',distance); //RFXSensor ID 004

//myx10.RFXmeter(12,0,distance);
delay(100);
// Sleep for 8 s  8 x 75 = 600 s = 10m
  for (int i=0; i<38; i++){
        system_sleep();
  }
delay(100);
}




/*
 * FUNCTION 
 */
// set system into the sleep state 
// system wakes up when wtchdog is timed out
void system_sleep() {
  cbi(ADCSRA,ADEN);                    // switch Analog to Digitalconverter OFF
  set_sleep_mode(SLEEP_MODE_PWR_DOWN); // sleep mode is set here
  sleep_enable();
  sleep_mode();                        // System sleeps here
  sleep_disable();                     // System continues execution here when watchdog timed out 
  sbi(ADCSRA,ADEN);                    // switch Analog to Digitalconverter ON
}

// 0=16ms, 1=32ms,2=64ms,3=128ms,4=250ms,5=500ms
// 6=1 sec,7=2 sec, 8=4 sec, 9= 8sec
void setup_watchdog(int ii) {

  byte bb;
  int ww;
  if (ii > 9 ) ii=9;
  bb=ii & 7;
  if (ii > 7) bb|= (1<<5);
  bb|= (1<<WDCE);
  ww=bb;

  MCUSR &= ~(1<<WDRF);
  // start timed sequence
  WDTCR |= (1<<WDCE) | (1<<WDE);
  // set new watchdog timeout value
  WDTCR = bb;
  WDTCR |= _BV(WDIE);
}
  
// Watchdog Interrupt Service / is executed when watchdog timed out
ISR(WDT_vect) {
  f_wdt=1;  // set global flag
}
