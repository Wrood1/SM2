
#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <Firebase_ESP_Client.h>

//Provide the token generation process info.
#include "addons/TokenHelper.h"
//Provide the RTDB payload printing info and other helper functions.
#include "addons/RTDBHelper.h"

// Insert Firebase project API Key
#define API_KEY "AIzaSyDUbfmKkpAG5P6y983ZVG8lh-xpxf2cqDw"

// Insert RTDB URLefine the RTDB URL */
#define DATABASE_URL "https://smart-64616-default-rtdb.firebaseio.com/"

//Define Firebase Data object
FirebaseData fbdo;

FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
int count = 0;
bool signupOK = false;

#include <WiFiManager.h>
#include <SoftwareSerial.h>
SoftwareSerial arduino(D2, D1);

String alarm_status = "";
String saved_Latitude = "";
String saved_Longitude = "";
String fire1 = "";
String fire2 = "";
String gas1 = "";
String gas2 = "";
String temp1 = "";
String hum1 = "";
String temp2 = "";
String hum2 = "";

void setup() {
  Serial.begin(9600);
  arduino.begin(115200);

  WiFiManager wm;
  bool res;
  res = wm.autoConnect("IOT", "12345678"); //192.168.4.1
  if (!res) {
    Serial.println("Failed to connect and hit timeout");
    delay(1000);
    // Reset and try again, or maybe put it to deep sleep
    //ESP.reset();
    delay(5000);
  } else {
    //if you get here you have connected to the WiFi
    Serial.println("connected...yeey :)");
  }

  /* Assign the api key (required) */
  config.api_key = API_KEY;

  /* Assign the RTDB URL (required) */
  config.database_url = DATABASE_URL;

  /* Sign up */
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("ok");
    signupOK = true;
  } else {
    Serial.printf("%s\n", config.signer.signupError.message.c_str());
  }

  /* Assign the callback function for the long running token generation task */
  config.token_status_callback = tokenStatusCallback;  //see addons/TokenHelper.h

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  read_from_arduino();

  if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > 10000 || sendDataPrevMillis == 0)) {
    send_data();
    sendDataPrevMillis = millis();
  }
}


void read_from_arduino() { 
  if (arduino.available() > 0) {
    String ss = arduino.readStringUntil('\n');
    int counter = 0;
    String data = "";
    for (int i = 0; i < ss.length(); i++) {
      if (ss[i] == ',') {
        counter++;
        if (counter == 1) alarm_status = data;
        else if (counter == 2) saved_Latitude = data;
        else if (counter == 3) saved_Longitude = data;
        else if (counter == 4) fire1 = data;
        else if (counter == 5) fire2 = data;
        else if (counter == 6) gas1 = data;
        else if (counter == 7) gas2 = data;
        else if (counter == 8) temp1 = data;
        else if (counter == 9) hum1 = data;
        else if (counter == 10) temp2 = data;
        else if (counter == 11) hum2 = data;
        data = "";
      } else {
        data = data + ss[i];
      }
    }

    Serial.print(alarm_status);
    Serial.print(" - ");
    Serial.print(saved_Latitude);
    Serial.print(" - ");
    Serial.print(saved_Longitude);
    Serial.print(" - ");
    Serial.print(fire1);
    Serial.print(" - ");
    Serial.print(fire2);
    Serial.print(" - ");
    Serial.print(gas1);
    Serial.print(" - ");
    Serial.print(gas2);
    Serial.print(" - ");
    Serial.print(temp1);
    Serial.print(" - ");
    Serial.print(hum1);
    Serial.print(" - ");
    Serial.print(temp2);
    Serial.print(" - ");
    Serial.print(hum2);

    Serial.println();
  }
}

void send_data() {

  if (Firebase.RTDB.setString(&fbdo, "/location1/alarm", alarm_status)) {
    Serial.println("send alarm_status:");
    Serial.println(alarm_status);
  } else {
    Serial.println("failed alarm_status:");
    Serial.println(alarm_status);
  }

  if (Firebase.RTDB.setString(&fbdo, "/location1/lat", saved_Latitude)) {
    Serial.println("send lat:");
    Serial.println(saved_Latitude);
  } else {
    Serial.println("failed lat:");
    Serial.println(saved_Latitude);
  }

  if (Firebase.RTDB.setString(&fbdo, "/location1/lon", saved_Longitude)) {
    Serial.println("send lon:");
    Serial.println(saved_Longitude);
  } else {
    Serial.println("failed lon:");
    Serial.println(saved_Longitude);
  }

  if (Firebase.RTDB.setString(&fbdo, "/location1/room2/fire", fire1)) {
    Serial.println("send fire1:");
    Serial.println(fire1);
  } else {
    Serial.println("failed fire1:");
    Serial.println(fire1);
  }

  if (Firebase.RTDB.setString(&fbdo, "/location1/room3/fire", fire2)) {
    Serial.println("send fire2:");
    Serial.println(fire2);
  } else {
    Serial.println("failed fire2:");
    Serial.println(fire2);
  }

  if (Firebase.RTDB.setString(&fbdo, "/location1/room1/gas", gas1)) {
    Serial.println("send gas1:");
    Serial.println(gas1);
  } else {
    Serial.println("failed gas1:");
    Serial.println(gas1);
  }

  if (Firebase.RTDB.setString(&fbdo, "/location1/room3/gas", gas2)) {
    Serial.println("send gas2:");
    Serial.println(gas2);
  } else {
    Serial.println("failed gas2:");
    Serial.println(gas2);
  }

  if (Firebase.RTDB.setString(&fbdo, "/location1/room1/temp", temp1)) {
    Serial.println("send temp1:");
    Serial.println(temp1);
  } else {
    Serial.println("failed temp1:");
    Serial.println(temp1);
  }

  if (Firebase.RTDB.setString(&fbdo, "/location1/room1/humidity", hum1)) {
    Serial.println("send hum1:");
    Serial.println(hum1);
  } else {
    Serial.println("failed hum1:");
    Serial.println(hum1);
  }

  if (Firebase.RTDB.setString(&fbdo, "/location1/room2/temp", temp2)) {
    Serial.println("send temp2:");
    Serial.println(temp2);
  } else {
    Serial.println("failed temp2:");
    Serial.println(temp2);
  }

  if (Firebase.RTDB.setString(&fbdo, "/location1/room2/humidity", hum2)) {
    Serial.println("send hum2:");
    Serial.println(hum2);
  } else {
    Serial.println("failed hum2:");
    Serial.println(hum2);
  }

}
