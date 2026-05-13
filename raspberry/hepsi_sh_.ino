#include <Wire.h>

#define MPU9250_IMU_ADDRESS 0x68
#define MPU9250_MAG_ADDRESS 0x0C

#define GYRO_FULL_SCALE_1000_DPS 0x10
#define ACC_FULL_SCALE_2G 0x00

#define G 9.80665

// ---------- Pin Tanımlamaları ----------
const int mq9Pin = A0;          // MQ9 analog çıkış
const int soilPin = A1;         // Nem sensörü analog çıkış
const int hw416Pin = 2;         // HW-416 dijital çıkış
const int buzzerPin = 8;        // Buzzer

// ---------- Zaman Aralıkları ----------
const unsigned long INTERVAL_IMU_PRINT = 500;
const unsigned long INTERVAL_SENSOR_READ = 1000;

unsigned long lastPrintMillis = 0;
unsigned long lastSensorMillis = 0;

// ---------- MPU9250 Verileri ----------
struct gyroscope_raw {
  int16_t x, y, z;
} gyroscope;

struct accelerometer_raw {
  int16_t x, y, z;
} accelerometer;

struct magnetometer_raw {
  int16_t x, y, z;
} magnetometer;

struct temperature_raw {
  int16_t value;
} temperature;

struct {
  struct { float x, y, z; } accelerometer, gyroscope, magnetometer;
  float temperature;
} normalized;

// ---------- Sensör Değerleri ----------
int mq9Raw = 0;
int soilRaw = 0;
int soilPercent = 0;
int motionDetected = 0;

// ---------- I2C Fonksiyonları ----------
void I2CwriteByte(uint8_t addr, uint8_t reg, uint8_t data) {
  Wire.beginTransmission(addr);
  Wire.write(reg);
  Wire.write(data);
  Wire.endTransmission();
}

uint8_t I2CreadByte(uint8_t addr, uint8_t reg) {
  Wire.beginTransmission(addr);
  Wire.write(reg);
  Wire.endTransmission(false);
  Wire.requestFrom(addr, (uint8_t)1);

  if (Wire.available()) {
    return Wire.read();
  }

  return 0;
}

void I2CreadBytes(uint8_t addr, uint8_t reg, uint8_t len, uint8_t* data) {
  Wire.beginTransmission(addr);
  Wire.write(reg);
  Wire.endTransmission(false);

  Wire.requestFrom(addr, len);

  for (uint8_t i = 0; i < len; i++) {
    if (Wire.available()) {
      data[i] = Wire.read();
    } else {
      data[i] = 0;
    }
  }
}

// ---------- MPU9250 Başlatma ----------
void setupMPU() {
  I2CwriteByte(MPU9250_IMU_ADDRESS, 0x6B, 0x00); // Wake up
  delay(100);

  I2CwriteByte(MPU9250_IMU_ADDRESS, 27, GYRO_FULL_SCALE_1000_DPS);
  I2CwriteByte(MPU9250_IMU_ADDRESS, 28, ACC_FULL_SCALE_2G);

  I2CwriteByte(MPU9250_IMU_ADDRESS, 0x37, 0x02); // Bypass mode

  delay(100);
}

// ---------- MPU9250 Okuma ----------
void readIMU() {
  uint8_t data[14];

  I2CreadBytes(MPU9250_IMU_ADDRESS, 0x3B, 14, data);

  accelerometer.x = (int16_t)((data[0] << 8) | data[1]);
  accelerometer.y = (int16_t)((data[2] << 8) | data[3]);
  accelerometer.z = (int16_t)((data[4] << 8) | data[5]);

  temperature.value = (int16_t)((data[6] << 8) | data[7]);

  gyroscope.x = (int16_t)((data[8] << 8) | data[9]);
  gyroscope.y = (int16_t)((data[10] << 8) | data[11]);
  gyroscope.z = (int16_t)((data[12] << 8) | data[13]);
}

// ---------- Magnetometre Okuma ----------
void readMag() {
  uint8_t data[6];

  I2CreadBytes(MPU9250_MAG_ADDRESS, 0x03, 6, data);

  magnetometer.x = (int16_t)((data[1] << 8) | data[0]);
  magnetometer.y = (int16_t)((data[3] << 8) | data[2]);
  magnetometer.z = (int16_t)((data[5] << 8) | data[4]);
}

// ---------- MPU9250 Normalize ----------
void normalizeData() {
  normalized.accelerometer.x = accelerometer.x * G / 16384.0;
  normalized.accelerometer.y = accelerometer.y * G / 16384.0;
  normalized.accelerometer.z = accelerometer.z * G / 16384.0;

  normalized.gyroscope.x = gyroscope.x / 32.8;
  normalized.gyroscope.y = gyroscope.y / 32.8;
  normalized.gyroscope.z = gyroscope.z / 32.8;

  normalized.temperature = (temperature.value / 333.87) + 21.0;

  normalized.magnetometer.x = magnetometer.x;
  normalized.magnetometer.y = magnetometer.y;
  normalized.magnetometer.z = magnetometer.z;
}

// ---------- Diğer Sensörleri Oku ----------
void readOtherSensors() {
  mq9Raw = analogRead(mq9Pin);

  soilRaw = analogRead(soilPin);
  soilPercent = map(soilRaw, 1023, 200, 0, 100);
  soilPercent = constrain(soilPercent, 0, 100);

  motionDetected = digitalRead(hw416Pin);
}

// ---------- Buzzer Kontrol ----------
void controlBuzzer() {
  bool alarm = false;

  // HW-416 hareket algılarsa
  if (motionDetected == HIGH) {
    alarm = true;
  }

  // MQ9 gaz değeri yüksekse
  // Bu eşik test edilerek ayarlanmalı.
  if (mq9Raw > 500) {
    alarm = true;
  }

  // Toprak çok kuruysa
  if (soilPercent < 20) {
    alarm = true;
  }

  if (alarm) {
    digitalWrite(buzzerPin, HIGH);
  } else {
    digitalWrite(buzzerPin, LOW);
  }
}

// ---------- Seri Monitöre Yazdır ----------
void printData() {
  Serial.println("========== SISTEM VERILERI ==========");

  Serial.println("---- MPU9250 ----");

  Serial.print("TEMP: ");
  Serial.print(normalized.temperature);
  Serial.println(" C");

  Serial.print("ACC: ");
  Serial.print(normalized.accelerometer.x); Serial.print(" ");
  Serial.print(normalized.accelerometer.y); Serial.print(" ");
  Serial.println(normalized.accelerometer.z);

  Serial.print("GYRO: ");
  Serial.print(normalized.gyroscope.x); Serial.print(" ");
  Serial.print(normalized.gyroscope.y); Serial.print(" ");
  Serial.println(normalized.gyroscope.z);

  Serial.print("MAG: ");
  Serial.print(normalized.magnetometer.x); Serial.print(" ");
  Serial.print(normalized.magnetometer.y); Serial.print(" ");
  Serial.println(normalized.magnetometer.z);

  Serial.println("---- MQ9 ----");

  Serial.print("MQ9 Ham Deger: ");
  Serial.println(mq9Raw);

  if (mq9Raw > 500) {
    Serial.println("MQ9 DURUM: Gaz seviyesi yuksek!");
  } else {
    Serial.println("MQ9 DURUM: Gaz seviyesi normal.");
  }

  Serial.println("---- TOPRAK NEM ----");

  Serial.print("Nem Ham Deger: ");
  Serial.print(soilRaw);
  Serial.print(" | Nem: %");
  Serial.println(soilPercent);

  if (soilPercent < 20) {
    Serial.println("NEM DURUM: Toprak cok kuru! Su verilmeli.");
  } else if (soilPercent > 80) {
    Serial.println("NEM DURUM: Toprak cok islak.");
  } else {
    Serial.println("NEM DURUM: Nem seviyesi ideal.");
  }

  Serial.println("---- HW-416 ----");

  Serial.print("Hareket: ");
  if (motionDetected == HIGH) {
    Serial.println("ALGILANDI");
  } else {
    Serial.println("YOK");
  }

  Serial.println("---- BUZZER ----");

  if (digitalRead(buzzerPin) == HIGH) {
    Serial.println("Buzzer: ACIK");
  } else {
    Serial.println("Buzzer: KAPALI");
  }

  Serial.println("=====================================");
  Serial.println();
}

// ---------- SETUP ----------
void setup() {
  Wire.begin();
  Serial.begin(9600);

  pinMode(hw416Pin, INPUT);
  pinMode(buzzerPin, OUTPUT);

  digitalWrite(buzzerPin, LOW);

  setupMPU();

  Serial.println("Sistem baslatildi.");
  Serial.println("MPU9250 + MQ9 + Nem Sensoru + HW-416 + Buzzer hazir.");
}

// ---------- LOOP ----------
void loop() {
  readIMU();
  readMag();
  normalizeData();

  if (millis() - lastSensorMillis >= INTERVAL_SENSOR_READ) {
    readOtherSensors();
    controlBuzzer();
    lastSensorMillis = millis();
  }

  if (millis() - lastPrintMillis >= INTERVAL_IMU_PRINT) {
    printData();
    lastPrintMillis = millis();
  }

  delay(50);
}
