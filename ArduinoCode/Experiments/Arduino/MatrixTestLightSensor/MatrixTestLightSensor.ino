#include <Arduino.h>   // required before wiring_private.h
#include "wiring_private.h" // pinPeripheral() function
#include <RGBmatrixPanel.h>

#define CLK  8   // USE THIS ON ARDUINO UNO, ADAFRUIT METRO M0, etc.
//#define CLK A4 // USE THIS ON METRO M4 (not M0)
//#define CLK 11 // USE THIS ON ARDUINO MEGA
#define OE   9
#define LAT 10
#define A   A0
#define B   A1
#define C   A2

RGBmatrixPanel matrix(A, B, C, CLK, LAT, OE, false);

Uart Serial2 (&sercom1, 11, 12, SERCOM_RX_PAD_3, UART_TX_PAD_0);
void SERCOM1_Handler()
{
  Serial2.IrqHandler();
}


int buttonState = 0;
int lastButtonState = 0;
int lastButtonPress = 0; //ms of button press
int lastLightValue;

String stringRemaining = ""; //String remaining after cut due to button or delay
String fullStartString = ""; //A string of the original string sent
String stringRemainingAfterRepeat = ""; //Only used during repeats
int delayStartTime = 0; //The millis of the dely start time
int delayTime = 0; //How long in total the delay is

bool waitingForButtonPress = false;
bool skippingNextButtonPress = false; //If allowed to skip button press in next send
int lastMessageRequestTime = 0;

int dotPosition = 0;
int dotVelocity = 1;
bool showNotification = false;
int hue = 0;
int lastNotificationUpdate = 0; //Time since last update of notification

bool startUp = true; //Ignores requesting new string when reading startup string
const String startup = "$f000000p15000015081608ed50f000000p150000140815081608170815091609ed50f000000p150000150616061407150716071707140815081608170815091609ed50f000000p15000014051705130614061506160617061806130714071507160717071807130814081508160817081808140915091609170915101610ed50f000000p1500001305140517051805120613061406150616061706180619061207130714071507160717071807190712081308140815081608170818081908130914091509160917091809141015101610171015111611ed50f000000p15000013041404170418041205130514051505160517051805190511061206130614061506160617061806190620061107120713071407150716071707180719072007110812081308140815081608170818081908200812091309140915091609170918091909131014101510161017101810141115111611171115121612ed50f000000p150000120313031803190311041204130414041704180419042004100511051205130514051505160517051805190520052105100611061206130614061506160617061806190620062106100711071207130714071507160717071807190720072107100811081208130814081508160817081808190820082108110912091309140915091609170918091909200912101310141015101610171018101910131114111511161117111811141215121612171215131613ed500f000000p15000013041404170418041205130514051505160517051805190511061206130614061506160617061806190620061107120713071407150716071707180719072007110812081308140815081608170818081908200812091309140915091609170918091909131014101510161017101810141115111611171115121612ed500f000000p150000120313031803190311041204130414041704180419042004100511051205130514051505160517051805190520052105100611061206130614061506160617061806190620062106100711071207130714071507160717071807190720072107100811081208130814081508160817081808190820082108110912091309140915091609170918091909200912101310141015101610171018101910131114111511161117111811141215121612171215131613ed500f000000p15000013041404170418041205130514051505160517051805190511061206130614061506160617061806190620061107120713071407150716071707180719072007110812081308140815081608170818081908200812091309140915091609170918091909131014101510161017101810141115111611171115121612ed500f000000p150000120313031803190311041204130414041704180419042004100511051205130514051505160517051805190520052105100611061206130614061506160617061806190620062106100711071207130714071507160717071807190720072107100811081208130814081508160817081808190820082108110912091309140915091609170918091909200912101310141015101610171018101910131114111511161117111811141215121612171215131613ed500f000000^";


// the setup function runs once when you press reset or power the board
void setup() {
  Serial.begin(115200);
  Serial2.begin(115200);
  
  // Assign pins 12 & 11 SERCOM functionality
  pinPeripheral(12, PIO_SERCOM);
  pinPeripheral(11, PIO_SERCOM);

  //Button init
  pinMode(13, INPUT);
  
  //Matrix init
  matrix.begin();

  readString(startup);
}

int timeSince(int lastTime) {
  return millis()-lastTime;
}

void requestNewMessage() {
  Serial2.write("O");
  lastMessageRequestTime = millis();
}

//Read string from serial
void readString(String string) {
  stringRemaining = "";
  showNotification = false;
  int length = string.length();
  int i = 0;
  Serial.println();
  while (i < length) {
    char ch = string[i];
    //Serial.print(ch);
    if (ch == 'f') {
      matrix.fillScreen(matrix.Color444((string[i+1]*10)+string[i+2], (string[i+3]*10)+string[i+4], (string[i+5]*10)+string[i+6]));
      i += 6;
    } else if (ch == 'p') {
      //
      String colors[3] = {String(string[i+1])+string[i+2], String(string[i+3])+string[i+4], String(string[i+5])+string[i+6]};
      i += 7;
      int timeNow = millis();
      while (string[i] != 'e' && timeSince(timeNow) < 10000) {
        String cords[2] = {String(string[i])+string[i+1], String(string[i+2])+string[i+3]};
        matrix.drawPixel(cords[0].toInt(), cords[1].toInt(), matrix.Color444(colors[0].toInt(), colors[1].toInt(), colors[2].toInt()));
        i += 4;
      }
    } else if (ch == 't') {
      matrix.setTextSize(String(string[i+1]).toInt());   // size 1 == 8 pixels high
      i+=2;
      if (string[i] == 'c') { //Set cursor if needed
        String cords[2] = {String(string[i+1])+string[i+2], String(string[i+3])+string[i+4]};
        matrix.setCursor(cords[0].toInt(), cords[1].toInt());
        i+=5;
      }
      String colors[3] = {String(string[i])+string[i+1], String(string[i+2])+string[i+3], String(string[i+4])+string[i+5]};
      matrix.setTextColor(matrix.Color444(colors[0].toInt(), colors[1].toInt(), colors[2].toInt()));
      i += 6;
      int timeNow = millis();
      while (string[i] != '|' && timeSince(timeNow) < 5000) {
        matrix.print(string[i]);
        i++;
      }
    } else if (ch == 'd') {
      i++;
      String delayString = "";
      int timeNow = millis();
      while (isDigit(string[i]) && timeSince(timeNow) < 5000) {
        delayString += String(string[i]);
        i++;
      }
      delayStartTime = millis();
      delayTime = delayString.toInt();
      String newString = string;
      newString.remove(0, i);
      stringRemaining = newString;
      Serial.print("String remaining:");
      Serial.println(newString);
      return;
      //delay(delayString.toInt());
    } else if ((ch == 'b' && !skippingNextButtonPress) || ch == 'n') {
      waitingForButtonPress = true;
      if (ch == 'b') {
        showNotification = true;
      }
      skippingNextButtonPress = true;
      String newString = string;
      newString.remove(0, i+1);
      stringRemaining = newString;
      Serial.print("String remaining:");
      Serial.println(newString);
      return;
    } else if (ch == 'r') {
      stringRemaining = fullStartString;
      delayStartTime = millis();
      delayTime = 0;
      String newString = string;
      newString.remove(0, i+1);
      stringRemainingAfterRepeat = newString;
      Serial.print("String remaining for repeat:");
      Serial.println(newString);
      return;
    }
    i++;
    if (i == length) {
      if (startUp) {
        startUp = false;
      } else {
        Serial.println("Done with String, Requesting next value");
        requestNewMessage();
      }
    }
  }
}


// the loop function runs over and over again forever
void loop() {
  if (Serial2.available()){
    int value = Serial2.read();
    char ch = (char)value;
    Serial.print(ch);
    if (ch == '$') {
      if (timeSince(lastMessageRequestTime) > 10000 && skippingNextButtonPress) {
        skippingNextButtonPress = false;
      }
      stringRemainingAfterRepeat = "";
      String data = "";
      int timeNow = millis();
      while (ch != '^' && timeSince(timeNow) < 10000) {
        if (Serial2.available()){
          value = Serial2.read();
          ch = (char)value;
          //Serial.print(ch);
          if (ch != '^') {
            data += ch;
          }
        }
      }
      if (timeSince(timeNow) >= 10000) {
        Serial.println("Error, string never finished");
      } else {
        Serial.print(data);
        fullStartString = data;
        readString(data);
        Serial.println();
      }
    }
  }
  //Delay code
  if (stringRemaining != "" && timeSince(delayStartTime) >= delayTime && !waitingForButtonPress) {
    readString(stringRemaining);
  }
  //Notification
  if (showNotification && timeSince(lastNotificationUpdate) > 30) {
    matrix.fillScreen(0);
    if (lastLightValue == HIGH) {
      for(int i=0; i<3; i++) {
        matrix.drawPixel(dotPosition-(i*dotVelocity), 0, matrix.ColorHSV(hue, 255, 255, true));
        if (dotPosition == -10 || dotPosition == 34) {
          dotVelocity *= -1;
        }
      }
      dotPosition += dotVelocity;
    } else {
      matrix.drawPixel(0, 0, matrix.ColorHSV(hue, 255, 255, true));
    }
    
    hue += 3;
    if(hue >= 1536) hue -= 1536;
    lastNotificationUpdate = millis();
  }
  //Button
  buttonState = digitalRead(13);
  if (buttonState == 1 && lastButtonState == 0 && timeSince(lastButtonPress) > 500) {
    Serial.print(analogRead(A4)/200);
    if (stringRemaining == "" && stringRemainingAfterRepeat == "") {
      Serial.println("Requesting next value");
      requestNewMessage();
    } else if (stringRemainingAfterRepeat != "") {
      Serial.println("Reading repeat string");
      readString(stringRemainingAfterRepeat);
      stringRemainingAfterRepeat = "";
    } else {
      Serial.println("Reading remaining string");
      readString(stringRemaining);
      waitingForButtonPress = false;
    }
    lastButtonPress = millis();
  }
  lastButtonState = buttonState;
  //Light sensor
  int currentValue = analogRead(A4)/200;
  if (lastLightValue == 0 && currentValue > 4) {
    Serial.print(currentValue);
    //readString("f150000");
    Serial2.write("H");
    lastLightValue = 1;
  } else if (lastLightValue == 1 && currentValue < 3) {
    //readString("f000000");
    Serial2.write("L");
    lastLightValue = 0;
  }
  
}
