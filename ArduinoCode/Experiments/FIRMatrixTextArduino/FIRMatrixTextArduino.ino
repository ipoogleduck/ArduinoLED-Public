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


// the setup function runs once when you press reset or power the board
void setup() {
  Serial.begin(9600);
  // initialize digital pin LED_BUILTIN as an output.
  pinMode(LED_BUILTIN, OUTPUT);
  //Matrix init
  matrix.begin();
}

// the loop function runs over and over again forever
void loop() {
  if (Serial.available()){
    char ch = Serial.read();
    if (ch == '1') {
      digitalWrite(LED_BUILTIN, HIGH);   // turn the LED on (HIGH is the voltage level)
      matrix.fillScreen(matrix.Color333(7, 7, 7));
    } else if (ch == '0') {
      digitalWrite(LED_BUILTIN, LOW);    // turn the LED off by making the voltage LOW
      matrix.fillScreen(matrix.Color333(1, 1, 1));
    }
    Serial.print(ch);
  }
}
