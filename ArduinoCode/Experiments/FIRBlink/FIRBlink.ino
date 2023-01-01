#include <ESP8266WiFi.h>
#include <FirebaseArduino.h>
//#include <RGBmatrixPanel.h>

// Set these to run example.
#define FIREBASE_HOST "arduinoled-5549d-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "c8WAjxirwh9HdQStARv6uyoSEfNmfLtmyeRw0T50"
#define WIFI_SSID "BumbleBoo Secure"
#define WIFI_PASSWORD "Waspbeee"

void setup() {
  Serial.begin(9600);

  pinMode(LED_BUILTIN, OUTPUT);     // Initialize the LED_BUILTIN pin as an output
  
  // connect to wifi.
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("connecting to wifi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println();
  Serial.print("connected: ");
  Serial.println(WiFi.localIP());

  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  Firebase.stream("LEDSwitch"); 
}

// the loop function runs over and over again forever
void loop() {

  if (Firebase.failed()) {
    Serial.println("streaming error");
    Serial.println(Firebase.error());
  }
  
  if (Firebase.available()) {
     FirebaseObject event = Firebase.readEvent();
     String eventType = event.getString("type");
     eventType.toLowerCase();
     
     Serial.print("event: ");
     Serial.println(eventType);
     if (eventType == "put") {
       bool isOn = Firebase.getBool("LEDSwitch/isOn");
       Serial.println(isOn);
     }
  }   

//  // get value
//  bool isOn = Firebase.getBool("LEDSwitch/isOn");
//  Serial.println(isOn);
//  delay(1000);
}
