# Akilli Ev Mobil Uygulamasi

Bu proje, Flutter ile gelistirilmis bir akilli ev mobil uygulamasidir. Uygulama; kullanici girisi, ev kurulum paketi secimi, oda ve cihaz kontrolu, canli sensor takibi, alarm gecmisi, kamera goruntuleri, destek mesaji ve admin yonetimi gibi akilli ev senaryolarini tek mobil arayuzde toplar.

Uygulama Flutter tarafinda temiz katmanli bir yapi kullanir. Kimlik dogrulama icin Supabase, backend servisleri icin FastAPI tabanli HTTP API, canli sensor verileri icin MQTT, lokal cache icin SQLite, alarm kayitlari ve push bildirimleri icin Firebase servisleri kullanilir.

## Icindekiler

- [Ozellikler](#ozellikler)
- [Teknoloji Yigini](#teknoloji-yigini)
- [Proje Mimarisi](#proje-mimarisi)
- [Klasor Yapisi](#klasor-yapisi)
- [Uygulama Akisi](#uygulama-akisi)
- [Ekranlar](#ekranlar)
- [Veri Kaynaklari](#veri-kaynaklari)
- [Ortam Degiskenleri](#ortam-degiskenleri)
- [Kurulum](#kurulum)
- [Calistirma](#calistirma)
- [Testler](#testler)
- [Firebase ve Firestore](#firebase-ve-firestore)
- [MQTT Sensor Akisi](#mqtt-sensor-akisi)
- [Offline Cache](#offline-cache)
- [Backend API Beklentileri](#backend-api-beklentileri)
- [Sorun Giderme](#sorun-giderme)
- [Gelistirme Notlari](#gelistirme-notlari)

## Ozellikler

- Supabase ile oturum acma, oturum takibi ve sifre sifirlama akisi.
- Backend tarafindan gelen kullanici rolune gore kullanici veya admin arayuzu.
- Ilk kurulum tamamlanmadiysa paket secimi ve ev sehri tanimlama ekrani.
- Ana sayfada ev durumu, hava durumu, Raspberry Pi sistem durumu ve hizli erisimler.
- MQTT uzerinden canli sensor verisi dinleme.
- Sensor verilerini grafik, kart ve alarm durumlariyla gosterme.
- Esik deger asiminda uygulama ici uyari, lokal bildirim ve Firestore alarm log kaydi.
- Internet/API/MQTT sorunu olursa SQLite cache uzerinden son sensor verilerini gosterebilme.
- Odalara gore cihaz listeleme ve cihaz ac/kapat komutu gonderme.
- Kamera ekraninda lokal video assetleri ile kamera goruntusu deneyimi.
- Kullanici ve admin arasinda destek mesaji akisi.
- Admin tarafinda kullanici, oda, cihaz ve sensor yonetimi.
- Firebase Cloud Messaging token alma ve backend'e gonderme.
- Unit, widget ve integration test kapsami.

## Teknoloji Yigini

| Katman | Teknoloji / Paket | Kullanim Amaci |
| --- | --- | --- |
| UI | Flutter, Material, Google Fonts | Mobil arayuz ve tema |
| State Management | provider | ViewModel'leri widget agacina saglama |
| Auth | supabase_flutter | Oturum, sifre sifirlama, auth state takibi |
| Backend | http | FastAPI endpointlerine REST istekleri |
| Realtime Sensor | mqtt_client | MQTT broker uzerinden canli sensor verisi |
| Lokal Veri | sqflite, path | Sensor cache veritabani |
| Baglanti Kontrolu | connectivity_plus | Online/offline durumuna gore veri stratejisi |
| Grafik | fl_chart | Sensor grafik gosterimleri |
| Video | video_player | Kamera video assetlerini oynatma |
| Bildirim | flutter_local_notifications | Lokal sensor alarm bildirimleri |
| Firebase | firebase_core, firebase_messaging, cloud_firestore | FCM ve alarm loglari |
| Yardimci | intl, shared_preferences | Tarih bicimleme ve kullanici ayarlari |
| Test | flutter_test, integration_test | Unit, widget ve integration testler |

## Proje Mimarisi

Proje genel olarak Clean Architecture prensiplerine yakin bir katman ayrimi kullanir:

```text
lib/
  config/          Ortamdan okunan uygulama konfigleri
  core/            Ortak altyapi, lokal veritabani sabitleri
  data/            API, MQTT, Firebase, local datasource ve repository impl.
  domain/          Entity ve repository contract tanimlari
  presentation/    Ekranlar, widgetlar ve viewmodel siniflari
```

### Katman Sorumluluklari

| Katman | Sorumluluk |
| --- | --- |
| `domain/entities` | Uygulamanin temel veri tipleri: sensor, oda, cihaz, alarm logu |
| `domain/repositories` | Data katmanindan beklenen contract'lar |
| `data/datasources` | HTTP API, MQTT ve Firebase gibi dis kaynaklarla konusma |
| `data/local` | SQLite DAO ve lokal datasource islemleri |
| `data/repositories` | Remote/local veri kaynaklarini birlestiren is mantigi |
| `presentation/viewmodels` | UI state, loading/error durumlari ve kullanici aksiyonlari |
| `presentation/screens` | Uygulama ekranlari |
| `presentation/widgets` | Tekrar kullanilabilir UI bilesenleri |

## Klasor Yapisi

```text
android/                         Android proje dosyalari
ios/                             iOS proje dosyalari
assets/videos/                   Kamera ekraninda kullanilan video assetleri
integration_test/                Integration test senaryolari
test/                            Unit ve widget testleri
lib/main.dart                    Uygulama giris noktasi, provider ve route akisi
lib/config/api_config.dart       BACKEND_URL dart-define okuma
lib/data/datasources/            API, MQTT, Firebase ve mock datasource siniflari
lib/data/local/                  Sensor cache DAO ve datasource
lib/data/repositories/           Repository implementasyonlari
lib/data/services/               Bildirim, Firebase ve ayar servisleri
lib/domain/entities/             Domain modelleri
lib/domain/repositories/         Repository arayuzleri
lib/presentation/screens/        Kullanici ve admin ekranlari
lib/presentation/viewmodels/     Provider ile kullanilan state siniflari
lib/presentation/widgets/        Sensor karti, chat balonu, offline banner vb.
firestore.rules                  Firestore alarm log guvenlik kurallari
TEST_CASES.md                    Test case ozeti
```

## Uygulama Akisi

1. `main()` once Flutter binding'i hazirlar.
2. Firebase initialize edilir.
3. `SUPABASE_URL` ve `SUPABASE_ANON_KEY` dart-define degerleri okunur.
4. Supabase konfigu varsa Supabase baslatilir.
5. Lokal bildirim servisi ve Firebase Messaging servisi baslatilir.
6. `SmartHomeApp` calisir.
7. Supabase ayarlari eksikse config uyari ekrani gosterilir.
8. Ayarlar tamamsa provider'lar olusturulur:
   - `AuthViewModel`
   - `FirebaseAlarmLogViewModel`
   - `AdminViewModel`
   - `SensorViewModel`
   - `ControlViewModel`
9. `AuthGate` Supabase session durumunu dinler.
10. Session yoksa `LoginScreen`, sifre kurtarma olayi varsa `ResetPasswordScreen` acilir.
11. Session varsa backend `/me` endpointi ile kullanici rolu okunur.
12. Admin kullanici `AdminScreen` ekranina yonlendirilir.
13. Normal kullanici icin `/setup/status` kontrol edilir.
14. Kurulum eksikse `SetupPackageScreen`, tamamlanmissa `MainScreen` acilir.

## Ekranlar

### Kullanici Ekranlari

| Ekran | Dosya | Aciklama |
| --- | --- | --- |
| Giris | `lib/presentation/screens/login_screen.dart` | Supabase oturum acma ve kullanici girisi |
| Sifre Sifirlama | `reset_password_screen.dart` | Password recovery event sonrasi yeni sifre akisi |
| Kurulum Paketi | `setup_package_screen.dart` | Kullanici icin oda/cihaz/sensor paketini uygular |
| Ana Sayfa | `home_screen.dart` | Hava durumu, sistem durumu ve hizli erisimler |
| Sensorler | `sensors_screen.dart` | Canli sensor degerleri, grafikler ve Firestore alarm loglari |
| Kontrol | `control_screen.dart` | Odalara gore cihazlar ve ac/kapat aksiyonlari |
| Oda Detayi | `room_detail_screen.dart` | Secili odanin cihazlari ve durumlari |
| Istatistik | `stats_screen.dart` | Sensor/ev istatistikleri |
| Kamera | `camera_screen.dart` | Lokal kamera video assetleri |
| Kamera Olaylari | `camera_event_log_screen.dart` | Kamera olay gecmisi |
| Chat | `chat_screen.dart` | Kullanici-admin destek mesajlari |
| Profil | `profile_screen.dart` | Kullanici bilgileri ve profil islemleri |
| Bildirim Ayarlari | `notification_settings_screen.dart` | Alarm tiplerine gore bildirim tercihleri |
| Alarm Gecmisi | `alarm_history_screen.dart` | Firestore alarm log listesini gosterir |

### Admin Ekranlari

| Ekran | Dosya | Aciklama |
| --- | --- | --- |
| Admin Ana Ekrani | `admin_screen.dart` | Kullanicilari listeleme ve secili kullanici varliklarini yonetme |
| Admin Panel | `admin_panel_screen.dart` | Admin kisayollari ve yonetim ekrani |
| Admin Chat | `chat_screen.dart` | Secili kullanici ile destek yazismasi |

## Veri Kaynaklari

### HTTP API

`ApiService`, `ApiConfig.baseUrl` uzerinden FastAPI backend'e istek atar. Varsayilan backend adresi Android emulatore gore:

```text
http://10.0.2.2:8000
```

Gercek cihaz veya farkli ortam icin `BACKEND_URL` dart-define ile verilmelidir.

### Supabase

Supabase uygulamada ana auth saglayicisidir. `AuthGate`, Supabase session bilgisini dinleyerek giris, cikis ve sifre kurtarma ekranlarini yonetir. API isteklerinde Supabase access token `Authorization: Bearer <token>` header'i olarak gonderilir.

### MQTT

`MqttSensorService`, dart-define ile verilen broker bilgilerini kullanarak sensor topic'ine subscribe olur. Gelen JSON payload `SensorDataModel.fromMqttJson` ile domain modeline cevrilir.

### Firebase

Firebase iki amacla kullanilir:

- FCM token alinir ve backend'e `/fcm-token` endpointiyle gonderilir.
- Sensor alarm durumlari Firestore `sensor_alarm_logs` koleksiyonuna yazilir ve UI tarafinda stream olarak izlenir.

### SQLite Cache

Sensor verileri `smart_home_cache.db` veritabaninda `sensor_readings` tablosuna yazilir. API veya MQTT tarafinda hata olursa son cache verisi kullaniciya gosterilir.

## Ortam Degiskenleri

Uygulama runtime konfiglerini `--dart-define` ile okur.

| Degisken | Zorunlu | Varsayilan | Aciklama |
| --- | --- | --- | --- |
| `SUPABASE_URL` | Evet | Yok | Supabase proje URL'i |
| `SUPABASE_ANON_KEY` | Evet | Yok | Supabase anon public key |
| `BACKEND_URL` | Hayir | `http://10.0.2.2:8000` | FastAPI backend adresi |
| `MQTT_BROKER` | MQTT icin evet | Yok | MQTT broker host |
| `MQTT_PORT` | Hayir | `8883` | MQTT broker portu |
| `MQTT_USERNAME` | MQTT icin evet | Yok | MQTT kullanici adi |
| `MQTT_PASSWORD` | MQTT icin evet | Yok | MQTT sifresi |
| `MQTT_TOPIC` | Hayir | `ev/sensorler` | Sensor verilerinin dinlendigi topic |
| `MQTT_TLS` | Hayir | `true` | TLS kullanimi |

## Kurulum

### Gereksinimler

- Flutter SDK
- Dart SDK
- Android Studio veya Xcode
- Calisan FastAPI backend
- Supabase projesi
- Firebase projesi
- MQTT broker

### Bagimliliklari Kurma

```bash
flutter pub get
```

### Android Firebase Ayari

Android icin Firebase config dosyasi su konumda bulunmalidir:

```text
android/app/google-services.json
```

Bu dosya repo icinde mevcut gorunmektedir. Farkli Firebase projesi kullanilacaksa dosya guncellenmelidir.

### iOS Firebase Ayari

iOS icin Firebase kullaniminda `GoogleService-Info.plist` dosyasi Runner projesine eklenmelidir. Ayrica bildirim izinleri ve APNs ayarlari Firebase Console tarafindan tamamlanmalidir.

## Calistirma

### Android Emulator

Backend lokal makinede `localhost:8000` uzerinde calisiyorsa Android emulator icin varsayilan `10.0.2.2` adresi yeterlidir.

```bash
flutter run \
  --dart-define=SUPABASE_URL="https://PROJECT.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="SUPABASE_ANON_KEY" \
  --dart-define=MQTT_BROKER="broker.example.com" \
  --dart-define=MQTT_USERNAME="username" \
  --dart-define=MQTT_PASSWORD="password"
```

### Gercek Cihaz

Gercek cihazda backend adresi bilgisayarin yerel ag IP'si veya yayinlanmis API adresi olmalidir.

```bash
flutter run \
  --dart-define=SUPABASE_URL="https://PROJECT.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="SUPABASE_ANON_KEY" \
  --dart-define=BACKEND_URL="http://192.168.1.20:8000" \
  --dart-define=MQTT_BROKER="broker.example.com" \
  --dart-define=MQTT_USERNAME="username" \
  --dart-define=MQTT_PASSWORD="password"
```

### PowerShell Yardimci Script

Projede `run_flutter_mqtt.ps1` dosyasi vardir. MQTT bilgilerini merkezi sekilde vermek icin bu script kullanilabilir.

```powershell
.\run_flutter_mqtt.ps1
```

## Testler

Test dokumu `TEST_CASES.md` dosyasinda ayrica ozetlenmistir.

### Unit Testler

Model ve entity davranislari test edilir:

- `Message.fromJson`
- `SensorDataModel.fromJson`
- `SensorDataModel.toCacheMap`
- `ControlDevice.copyWith`

### Widget Testler

Temel UI bilesenleri test edilir:

- `ChatBubble`
- `MessageInputField`
- `SensorCard`
- `SmartHomeApp` config eksik durumu

### Integration Test

`integration_test/chat_flow_test.dart` icinde mesaj input akisi, sensor alarm UI davranisi,
config baslangic ekrani ve oda secimi -> cihaz kontrolu UI akisi test edilir.

### Test Komutlari

```bash
flutter analyze
flutter test
flutter test integration_test/chat_flow_test.dart
```

Son bilinen test ozeti:

- `flutter analyze`: No issues found
- `flutter test`: 16 test passed
- `flutter test integration_test/chat_flow_test.dart`: 5 test passed

## Firebase ve Firestore

Firestore alarm log koleksiyonu:

```text
sensor_alarm_logs
```

Kayit alanlari:

| Alan | Tip | Aciklama |
| --- | --- | --- |
| `reading_id` | int | Sensor okuma ID'si |
| `sensor_id` | int | Sensor ID'si |
| `device_id` | string | Ilgili cihaz ID'si |
| `labels` | list | Alarm etiketleri |
| `temperature` | number/null | Sicaklik |
| `humidity` | number/null | Nem |
| `gas_level` | number/null | Gaz seviyesi |
| `soil_moisture` | number/null | Toprak nemi |
| `created_at` | timestamp | Sensor okuma zamani |
| `written_at` | server timestamp | Firestore yazim zamani |

`firestore.rules` dosyasi sadece oturum acmis kullanicilarin okuma ve create islemi yapmasina izin verir. Update ve delete kapatilmistir.

## MQTT Sensor Akisi

Canli sensor akisi su sirayla calisir:

1. `SensorViewModel.connectLiveReadings()` cagrilir.
2. Repository remote datasource uzerinden MQTT baglantisi acar.
3. `MqttSensorService` broker'a baglanir ve topic'e subscribe olur.
4. Gelen payload JSON olarak parse edilir.
5. JSON `SensorDataModel` nesnesine cevrilir.
6. ViewModel son veriyi UI'a bildirir.
7. Veri SQLite cache'e yazilir.
8. Esik deger asimi varsa alarm etiketi uretilir.
9. Alarm icin Firestore logu ve lokal bildirim tetiklenir.

Beklenen MQTT payload'i sensor modelindeki alanlarla uyumlu olmalidir. Sicaklik, nem, gaz, isik, mesafe, toprak nemi, hareket, buzzer, accelerometer ve gyroscope gibi alanlar desteklenir.

## Offline Cache

Offline-first sensor mantigi `SensorRepositoryImpl` icinde uygulanir.

- Cihaz online ise once remote API/MQTT verisi denenir.
- Remote veri basarili olursa SQLite cache guncellenir.
- Remote hata verirse veya cihaz offline ise cache okunur.
- Cache de bos ise kullaniciya hata state'i gosterilir.
- Canli MQTT baglansa bile 4 saniye icinde veri gelmezse cache fallback tetiklenir.

SQLite tablo adi:

```text
sensor_readings
```

Veritabani adi:

```text
smart_home_cache.db
```

## Backend API Beklentileri

Mobil uygulama backend tarafinda asagidaki endpointleri bekler:

| Method | Endpoint | Amac |
| --- | --- | --- |
| `GET` | `/me` | Aktif kullanici bilgisi ve admin rolu |
| `GET` | `/setup/status` | Kurulum tamamlandi mi kontrolu |
| `POST` | `/setup/package` | Kullaniciya hazir ev paketi uygulama |
| `GET` | `/sensors/latest` | Son sensor okumasini alma |
| `GET` | `/sensors` | Sensor gecmisini alma |
| `GET` | `/sensor-definitions` | Kullanici sensor tanimlari |
| `GET` | `/rooms` | Kullanici odalari |
| `GET` | `/devices` | Kullanici cihazlari |
| `POST` | `/control` | Cihaz kontrol komutu gonderme |
| `GET` | `/weather/current` | Guncel hava durumu |
| `GET` | `/chat/messages` | Chat mesajlari |
| `POST` | `/chat/messages` | Chat mesaji gonderme |
| `POST` | `/fcm-token` | FCM token kaydetme |
| `GET` | `/admin/users` | Admin icin kullanicilar |
| `DELETE` | `/admin/users/{userId}` | Kullanici silme |
| `GET` | `/admin/users/{userId}/rooms` | Secili kullanicinin odalari |
| `GET` | `/admin/users/{userId}/devices` | Secili kullanicinin cihazlari |
| `GET` | `/admin/users/{userId}/sensors` | Secili kullanicinin sensorleri |
| `POST` | `/admin/rooms` | Secili kullaniciya oda ekleme |
| `POST` | `/admin/devices` | Secili kullaniciya cihaz ekleme |
| `POST` | `/admin/sensors` | Secili kullaniciya sensor ekleme |
| `DELETE` | `/admin/rooms/{roomId}` | Oda silme |
| `DELETE` | `/admin/devices/{deviceId}` | Cihaz silme |
| `DELETE` | `/admin/sensors/{sensorId}` | Sensor silme |

Yetki gerektiren isteklerde Supabase access token su header ile gonderilir:

```text
Authorization: Bearer <access_token>
```

## Sorun Giderme

### Supabase ayarlari eksik uyarisi

Sebep: `SUPABASE_URL` veya `SUPABASE_ANON_KEY` verilmemistir.

Cozum:

```bash
flutter run \
  --dart-define=SUPABASE_URL="https://PROJECT.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="SUPABASE_ANON_KEY"
```

### Backend baglantisi kurulamadi

Sebep: FastAPI sunucusu calismiyor, `BACKEND_URL` hatali veya gercek cihaz ayni aga erisemiyor olabilir.

Cozum:

- Backend'in calistigini kontrol edin.
- Android emulator icin `http://10.0.2.2:8000` kullanin.
- Gercek cihaz icin bilgisayarin yerel IP adresini kullanin.
- Backend CORS ayarlarini mobil istemciye gore kontrol edin.

### MQTT config eksik

Sebep: `MQTT_BROKER`, `MQTT_USERNAME` veya `MQTT_PASSWORD` eksiktir.

Cozum: MQTT dart-define degerlerini calistirma komutuna ekleyin.

### Canli sensor verisi gelmiyor

Kontrol listesi:

- Broker host ve port dogru mu?
- TLS ayari broker ile uyumlu mu?
- Topic adi `MQTT_TOPIC` ile eslesiyor mu?
- Payload JSON formati `SensorDataModel` ile uyumlu mu?
- Uygulama cache verisi gosteriyor olabilir; sensor ekranindaki cache uyarisini kontrol edin.

### Firestore alarm loglari gorunmuyor

Kontrol listesi:

- Firebase initialize basarili mi?
- Firestore rules deploy edildi mi?
- Kullanici Firebase/Supabase auth ile oturumlu mu?
- Sensor esik degerleri gercekten asiliyor mu?

## Gelistirme Notlari

- UI state icin `ChangeNotifier` ve `provider` kullanilir.
- Yeni bir backend endpointi eklenecekse once `ApiService`, sonra ilgili repository/viewmodel guncellenmelidir.
- Yeni sensor tipi eklenecekse `SensorData`, `SensorDataModel`, cache map donusumu, UI kartlari ve alarm threshold listesi birlikte ele alinmalidir.
- Yeni alarm tipi eklendiginde `SensorViewModel.thresholds`, bildirim ayarlari ve testler guncellenmelidir.
- Admin islemlerinde secili kullanici ID'si backend'e `target_user_id` olarak gonderilir.
- Dokumantasyon ve test case ozetleri degistiginde `README.md` ve `TEST_CASES.md` birlikte guncel tutulmalidir.
