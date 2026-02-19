#include <Arduino.h>
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

/* 1. Define the WiFi credentials */
#define WIFI_SSID "Realme5"
#define WIFI_PASSWORD "hhhh12345678"

/* 2. Define the API Key */
#define API_KEY "AIzaSyD8lpvhnfj2D2Dm_OO9ptlApk2CBd-SdiY"

/* 3. Define the RTDB URL */
#define DATABASE_URL "hospitaliot-himmti3b-default-rtdb.firebaseio.com" //<databaseName>.firebaseio.com or <databaseName>.<region>.firebasedatabase.app

/* 4. Define the user Email and password */
#define USER_EMAIL "esp32@testmail.com"
#define USER_PASSWORD "12345678"

// Define Firebase Data object
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Variabel waktu untuk pembacaan berkala
unsigned long readDataPrevMillis = 0;

// Definisi pin lampu indikator
#define LAMPU_P1_AMAN 27
#define LAMPU_P1_BANTUAN 14
#define LAMPU_P2_AMAN 12
#define LAMPU_P2_BANTUAN 13

void setup()
{
  Serial.begin(115200);

  pinMode(LAMPU_P1_AMAN, OUTPUT);
  pinMode(LAMPU_P1_BANTUAN, OUTPUT);
  pinMode(LAMPU_P2_AMAN, OUTPUT);
  pinMode(LAMPU_P2_BANTUAN, OUTPUT);

  digitalWrite(LAMPU_P1_AMAN, LOW);
  digitalWrite(LAMPU_P1_BANTUAN, LOW);
  digitalWrite(LAMPU_P2_AMAN, LOW);
  digitalWrite(LAMPU_P2_BANTUAN, LOW);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED)
  {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();

  Serial.printf("Firebase Client v%s\n\n", FIREBASE_CLIENT_VERSION);

  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;

  Firebase.reconnectNetwork(true);
  fbdo.setBSSLBufferSize(4096, 1024);

  Firebase.begin(&config, &auth);
  Firebase.setDoubleDigits(5);
}

void loop()
{
  if (Firebase.ready() && (millis() - readDataPrevMillis > 3000 || readDataPrevMillis == 0))
  {
    readDataPrevMillis = millis();

    int statusP1 = -1;
    int statusP2 = -1;
    int counter = -1;

    // ==== BACA STATUS PASIEN 1 ====
    if (Firebase.getInt(fbdo, "/rumahsakit/pasien1/status"))
    {
      statusP1 = fbdo.intData();

      if (statusP1 == 0)
      {
        digitalWrite(LAMPU_P1_AMAN, HIGH);
        digitalWrite(LAMPU_P1_BANTUAN, LOW);
        Serial.println("pasien1 : aman");
      }
      else if (statusP1 == 1)
      {
        digitalWrite(LAMPU_P1_AMAN, LOW);
        digitalWrite(LAMPU_P1_BANTUAN, HIGH);
        Serial.println("pasien1 : butuh bantuan");
      }
      else
      {
        Serial.println("pasien1 : data tidak valid");
      }
    }
    else
    {
      Serial.print("Gagal membaca pasien1: ");
      Serial.println(fbdo.errorReason());
    }

    // ==== BACA STATUS PASIEN 2 ====
    if (Firebase.getInt(fbdo, "/rumahsakit/pasien2/status"))
    {
      statusP2 = fbdo.intData();

      if (statusP2 == 0)
      {
        digitalWrite(LAMPU_P2_AMAN, HIGH);
        digitalWrite(LAMPU_P2_BANTUAN, LOW);
        Serial.println("pasien2 : aman");
      }
      else if (statusP2 == 1)
      {
        digitalWrite(LAMPU_P2_AMAN, LOW);
        digitalWrite(LAMPU_P2_BANTUAN, HIGH);
        Serial.println("pasien2 : butuh bantuan");
      }
      else
      {
        Serial.println("pasien2 : data tidak valid");
      }
    }
    else
    {
      Serial.print("Gagal membaca pasien2: ");
      Serial.println(fbdo.errorReason());
    }

    // ==== BACA FREKUENSI MINTA BANTUAN ====
    if (Firebase.getInt(fbdo, "/rumahsakit/counter"))
    {
      counter = fbdo.intData();
      Serial.printf("Frekuensi minta bantuan: %d kali\n", counter);
    }
    else
    {
      Serial.print("Gagal membaca counter: ");
      Serial.println(fbdo.errorReason());
    }

    Serial.println("-----------------------------");
  }
}