/******************************************
# This script aim at reporting tack water level
#      using a pressure sensor kelelr Serie 26Y
# Site    : https://domotique.web2diz.net/
# Detail  : https://domotique.web2diz.net/?p=958
#
# License : CC BY-SA 4.0
#
/*******************************************/


/**
   PINS
**/
#define RF_OUT 11                 // OUTPUT RF 
#define SONDE_CUVE A3             // Sonde Cuve 26Y (Pink wire) 
#define THN132N                   // Define only T° sensor 


/**
  VARIABLES
**/
int ChanelCuve =  0xAC;          // Chanel pour niveau cuve. 
int niveau_cuve=1;            // Variable pour niveau cuve


/**
    MAIN SETUP
**/
void setup() {

// OTHER SETUP  
Serial.begin(9600);
}

void loop(){
    delay (5000);
     get_and_send_water_level();
}


/**
      FUNCTION
      get_and_send_waterl_level
**/
double  get_and_send_water_level(){
  bitClear(PRR, PRADC); ADCSRA |= bit(ADEN); // Enable the ADC
  delay(1000);
  // read the value from the sensor:
  double niveau_cuve = analogRead(SONDE_CUVE);
  delay(10);
  ADCSRA &= ~ bit(ADEN); bitSet(PRR, PRADC); // Disable the ADC to save power
  Serial.print("Cuve Level Read : ");
  Serial.println(niveau_cuve);
  sent_oregon(ChanelCuve,niveau_cuve/10 );    // Sent voltage
  return niveau_cuve;
}
