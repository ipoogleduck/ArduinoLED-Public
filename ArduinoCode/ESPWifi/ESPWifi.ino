#include <ESP8266WiFi.h>
#include <FirebaseArduino.h>

#include <ArduinoJson.h>
//#include <FirebaseObject.h>

#include <DNSServer.h>
#include <ESP8266WebServer.h>
#include <WiFiManager.h>      //https://github.com/tzapu/WiFiManager WiFi Configuration Magic
//#include <RGBmatrixPanel.h>

// Set these to run example.
#define FIREBASE_HOST "arduinoled-5549d-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "c8WAjxirwh9HdQStARv6uyoSEfNmfLtmyeRw0T50"

#define WIFI_SSID "BumbleExtend"
//#define WIFI_SSID "BumbleBoo Secure"
#define WIFI_PASSWORD "Waspbeee"

//#define WIFI_SSID "Sieć dom"
//#define WIFI_PASSWORD "festivemango221"


String oliverPath = "Oliver";
String juliaPath = "Julia";

String myPath = oliverPath;

void setup() {
  Serial.begin(115200);

  //WiFiManager wifiManager;

  //pinMode(LED_BUILTIN, OUTPUT);     // Initialize the LED_BUILTIN pin as an output
  
  // connect to wifi.
  //WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  delay(5000);
  Serial.println("connecting to wifi");
  int waitCount = 0;
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
    waitCount += 1;
    if (waitCount > 30) {
      Serial.println("$f000000t1c0100151515No|t1c0108151515Wifi|d2000f000000^");
    }
  }
  //wifiManager.autoConnect("ArduinoLED", "password");
  
  Serial.println();
  Serial.print("connected: ");
  Serial.println(WiFi.localIP());

  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  streamPath();
}

void streamPath() {
  Firebase.stream(myPath + "/update"); 
}

bool canSend = true;
String lastPath = "";

void writeLightSensor(bool lowLight) {
  Firebase.setBool(myPath + "/lowLight", lowLight);
  if (Firebase.failed()) {
    Firebase.setBool(myPath + "/lowLight", lowLight);
  }
}

void markLastMessageAsOpened() {
  Serial.print("Last Path String: ");
  Serial.println(lastPath);
  if (lastPath != "") {
    Firebase.remove(myPath + "/pendingLog/" + lastPath);
    if (Firebase.failed()) {
      Serial.println("Failed to remove path");
      Firebase.remove(myPath + "/pendingLog/" + lastPath);
    }
    Firebase.setBool("shallowLog/" + lastPath + "/opened", true);
    Serial.println("Marked as opened");
  }
}

void handleIncomingMessage() {
  String testArrayString = Firebase.getJsonVariant(myPath + "/pendingLog");
  if (testArrayString == "null") {
   Serial.println("No Data available");
  } else {
   int arrayLength = testArrayString.length()+1;
   char testArray[arrayLength];
   testArrayString.toCharArray(testArray, arrayLength);

   //Serial.println(testArray);
   
   StaticJsonBuffer<200> jsonBuffer;

   JsonObject& root = jsonBuffer.parseObject(testArray);

   Serial.println("Got incoming message");

   if (!root.success()) {
    Serial.println("parseObject() failed");
    return;
   }
   JsonObject::iterator it=root.begin();
   size_t rootSize = root.size();
   int indexToGet = rootSize-1;
   Serial.println(indexToGet);
   for (int i = 0; i < indexToGet; i++) {
    ++it;
   }
   String index = it->value.as<String>();
   Firebase.setBool(myPath + "/received", true);
   Firebase.setBool("shallowLog/" + index + "/delivered", true);
   if (canSend) {
    sendNextMessage();
   }
  }
}

void sendNextMessage() {
  String testArrayString = Firebase.getJsonVariant(myPath + "/pendingLog");
  if (testArrayString == "null") {
   Serial.println("No Data available");
  } else {
   int arrayLength = testArrayString.length()+1;
   char testArray[arrayLength];
   testArrayString.toCharArray(testArray, arrayLength);

   //Serial.println(testArray);
   
   StaticJsonBuffer<200> jsonBuffer;

   JsonObject& root = jsonBuffer.parseObject(testArray);

   if (!root.success()) {
    Serial.println("parseObject() failed");
    return;
   }
   JsonObject::iterator it=root.begin();
   String index = it->value.as<String>();
   Serial.println(index);
   String path = "fullLog/" + index;
   Serial.println(path);
   String fullString = Firebase.getString(path);
   canSend = false;
   Serial.println(fullString);
   lastPath = index;
   //Serial.println(test1);
  }
}

int errorCount = 0;

// the loop function runs over and over again forever
void loop() {

  if (Firebase.failed()) {
    Serial.println("streaming error");
    Serial.println(Firebase.error());
    delay(1000);
    if (errorCount == 3) {
      Serial.println("Retrying stream");
      streamPath();
    } else if (errorCount == 6) {
      Serial.println("$f000000t1c0100151515Wifi |t1c0108151515SigEr|^");
      Serial.println("Restarting...");
      ESP.restart();
    }
    errorCount += 1;
  }

  if (Firebase.available()) {
    Serial.println("Firebase Available");
    errorCount = 0;
     FirebaseObject event = Firebase.readEvent();
     String eventType = event.getString("type");
     eventType.toLowerCase();
     
     //Serial.print("event: ");
     //Serial.println(eventType);
     if (eventType == "put") {
      //bool doUpdate = Firebase.getBool("matrixTest/update");
      String liveText = Firebase.getString(myPath + "/live");
      if (liveText != "") {
        Serial.println("Live text:");
        Serial.println(liveText);
        lastPath = "";
        canSend = false;
        Firebase.remove(myPath + "/live");
      } else {
       handleIncomingMessage();
       }
      }
    }
  if (Serial.available()) {
    int value = Serial.read();
    char ch = (char)value;
    //char value = Serial.read();
    Serial.println(ch);
    if (ch == 'H') {
      writeLightSensor(false);
    } else if (ch == 'L') {
      writeLightSensor(true);
    } else if (ch == 'O') {
      markLastMessageAsOpened();
      canSend = true;
      sendNextMessage();
    }
  }
}
