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

Uart Serial2 (&sercom1, 11, 12, SERCOM_RX_PAD_0, UART_TX_PAD_2);
void SERCOM1_Handler()
{
  Serial2.IrqHandler();
}


// the setup function runs once when you press reset or power the board
void setup() {
  Serial.begin(115200);
  Serial2.begin(115200);
  
  // Assign pins 12 & 11 SERCOM functionality
  pinPeripheral(12, PIO_SERCOM);
  pinPeripheral(11, PIO_SERCOM);
  
  //Matrix init
  matrix.begin();
}

//Read string from serial
void readString(String string) {
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
        while (string[i] != 'e') {
          String cords[2] = {String(string[i])+string[i+1], String(string[i+2])+string[i+3]};
          matrix.drawPixel(cords[0].toInt(), cords[1].toInt(), matrix.Color444(colors[0].toInt(), colors[1].toInt(), colors[2].toInt()));
//          Serial.print(colors[0]);
//          Serial.print(colors[1]);
//          Serial.print(colors[2]);
//          Serial.print(cords[0]);
//          Serial.print(cords[1]);
//          Serial.println();
          i += 4;
        }
        
//        String cords[2];
//        for (int j = 0; j < 2; j++) {
//          i++;
//          ch = string[i];
//          while (ch != '.') {
//            cords[j] += ch;
//            //Serial.print(cords[j]);
//            i++;
//            ch = string[i];
//          }
//        }
//        
//        matrix.drawPixel(cords[0].toInt(), cords[1].toInt(), matrix.Color444());
//        i += 6;
      }
      i++;
    }
}

// the loop function runs over and over again forever
void loop() {
//   if (Serial2.available()) {
//    int value = Serial2.read();
//    Serial.print((char)value);
//  }
  if (Serial2.available()){
    int value = Serial2.read();
    char ch = (char)value;
    Serial.print(ch);
    if (ch == '$') {
      String data = "";
      while (ch != '^') {
        if (Serial2.available()){
          value = Serial2.read();
          ch = (char)value;
          //Serial.print(ch);
          if (ch != '^') {
            data += ch;
          }
        }
      }
      Serial.print(data);
      readString(data);
      Serial.println();
    }
  }
}
