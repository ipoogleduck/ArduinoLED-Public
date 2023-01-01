//Include WiFi library
#include <ESP8266WiFi.h>

//WifiManager
#include <DNSServer.h>
#include <ESP8266WebServer.h>
#include <WiFiManager.h>      //https://github.com/tzapu/WiFiManager WiFi Configuration Magic

//Include Firebase library (this library)
#include <Firebase_ESP_Client.h>

//Define the Firebase Data object
FirebaseData fbdo;

//Define the FirebaseAuth data for authentication data
FirebaseAuth auth;

// Define the FirebaseConfig data for config data
FirebaseConfig config;

String path = "matrixTest/update";

void setup() {
  Serial.begin(115200);

  WiFiManager wifiManager;

  //pinMode(LED_BUILTIN, OUTPUT);     // Initialize the LED_BUILTIN pin as an output
  
  // connect to wifi.
  //WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("connecting to wifi");
  wifiManager.autoConnect("ArduinoLED-1");
  
  Serial.println();
  Serial.print("connected: ");
  Serial.println(WiFi.localIP());

  //Assign the project host and api key 
  config.host = "arduinoled-5549d-default-rtdb.firebaseio.com";
  
  config.api_key = "c8WAjxirwh9HdQStARv6uyoSEfNmfLtmyeRw0T50";
  
  //Assign the user sign in credentials
  auth.user.email = "ipoogleduck@gmail.com";
  auth.user.password = "testAccount";
  
  //Initialize the library with the Firebase authen and config.
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  if (!Firebase.RTDB.beginStream(&fbdo, path.c_str()))
  {
    Serial.println("------------------------------------");
    Serial.println("Can't begin stream connection...");
    Serial.println("REASON: " + fbdo.errorReason());
    Serial.println("------------------------------------");
    Serial.println();
  }
}

// the loop function runs over and over again forever
void loop() {

//  if (!Firebase.RTDB.readStream(&fbdo))
//  {
//    Serial.println("------------------------------------");
//    Serial.println("Can't read stream data...");
//    Serial.println("REASON: " + fbdo.errorReason());
//    Serial.println("------------------------------------");
//    Serial.println();
//  }
//
//  if (fbdo.streamTimeout())
//  {
//    Serial.println("Stream timeout, resume streaming...");
//    Serial.println();
//  }
//
//  if (fbdo.streamAvailable())
//  {
//    Serial.println("------------------------------------");
//    Serial.println("Stream Data available...");
//    Serial.println("STREAM PATH: " + fbdo.streamPath());
//    Serial.println("EVENT PATH: " + fbdo.dataPath());
//    Serial.println("DATA TYPE: " + fbdo.dataType());
//    Serial.println("EVENT TYPE: " + fbdo.eventType());
//    Serial.print("VALUE: ");
//    printResult(fbdo);
//    Serial.println("------------------------------------");
//    Serial.println();
//  }
}
