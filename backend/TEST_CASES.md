# Backend Unit Test Case Ozeti

Backend testleri `pytest` kullanmadan Python standart kutuphanesindeki `unittest`
ile yazildi. Testler gercek PostgreSQL, Firebase veya ag baglantisi acmadan saf
birim davranislarini kontrol eder.

## Calistirma

```bash
python3 -m unittest discover -s backend/tests -p "test_*.py"
```

Daha detayli cikti icin:

```bash
python3 -m unittest discover -v -s backend/tests -p "test_*.py"
```

## Unit Testler

| ID | Test Adi / Aciklama | On Kosul | Test Adimlari | Beklenen Sonuc | Durum |
| --- | --- | --- | --- | --- | --- |
| BUT-01 | Bearer token icinden kullanici UUID okunur | Gecerli JWT payload vardir | `get_current_user_id` cagrilir | `sub` claim'i UUID olarak doner | Gecti |
| BUT-02 | Claims icine `user_id` UUID eklenir | Gecerli JWT payload vardir | `get_current_user_claims` cagrilir | Payload korunur ve `user_id` eklenir | Gecti |
| BUT-03 | Eksik token 401 hatasi uretir | Authorization yoktur | `get_current_user_id(None)` cagrilir | `HTTPException(401)` doner | Gecti |
| BUT-04 | Yanlis imza 401 hatasi uretir | JWT secret tanimlidir | Yanlis secret ile token dogrulanir | `Token dogrulanamadi` hatasi doner | Gecti |
| BUT-05 | SensorReading property alanlari `data` icinden okunur | Sensor JSON data vardir | Property'ler okunur | Sicaklik, nem, gaz, isik, mesafe degerleri doner | Gecti |
| BUT-06 | SensorReading bos data icin `None` doner | `data=None` verilir | Property'ler okunur | Tum opsiyonel sensor alanlari `None` olur | Gecti |
| BUT-07 | ControlCommand varsayilanlari uygulanir | Sadece `target_id` ve `action` verilir | Schema olusturulur | `target_type=device`, `value=None` olur | Gecti |
| BUT-08 | ChatMessageCreate metni business logic'e birakir | Bosluklu metin verilir | Schema olusturulur | Metin oldugu gibi korunur | Gecti |
| BUT-09 | SensorCreate varsayilan aktif gelir | Room verilmeden sensor olusturulur | Schema olusturulur | `active=True`, `room_id=None` olur | Gecti |
| BUT-10 | UserOut SQLAlchemy modelinden validate edilir | User modeli vardir | `model_validate` cagrilir | Kullanici alanlari response schema'ya aktarilir | Gecti |
| BUT-11 | FCMTokenIn token alanini zorunlu tutar | Token verilmez | Schema olusturulur | Pydantic validation hatasi olusur | Gecti |
| BUT-12 | Weather code metne map edilir | Bilinen ve bilinmeyen kodlar vardir | `_weather_condition` cagrilir | Dogru Turkce kosul metni doner | Gecti |
| BUT-13 | Bos sehir geocode icin 400 hatasi verir | Sehir bos metindir | `_geocode_city` cagrilir | `Ev sehri gerekli` hatasi doner | Gecti |
| BUT-14 | Firebase tekil bildirim basarili sonucu doner | Firebase send mock'lanmistir | `send_sensor_alert` cagrilir | `True` doner ve mesaj alani dogru kurulur | Gecti |
| BUT-15 | Firebase tekil bildirim hatasinda false doner | Firebase send hata firlatir | `send_sensor_alert` cagrilir | `False` doner | Gecti |
| BUT-16 | Firebase multicast sayaclarini doner | Multicast response mock'lanmistir | `send_multicast_alert` cagrilir | Success/failure sayilari doner | Gecti |
| BUT-17 | Firebase multicast hatasinda tum tokenlar failed sayilir | Multicast hata firlatir | `send_multicast_alert` cagrilir | `success=0`, `failure=token_sayisi` doner | Gecti |
| BUT-18 | Malformed JWT token 401 hatasi verir | Token 3 parcali JWT formatinda degildir | `get_current_user_id` cagrilir | `Gecersiz token` hatasi doner | Gecti |
| BUT-19 | UUID olmayan `sub` claim 401 hatasi verir | Token payload `sub=not-uuid` icerir | `get_current_user_id` cagrilir | Kullanici bilgisi okunamadi hatasi doner | Gecti |
| BUT-20 | Hava durumu servisi basarili payload doner | Open-Meteo yaniti mock'lanmistir | `get_current_weather` cagrilir | Sicaklik, nem, ruzgar, UV ve kosul doner | Gecti |
| BUT-21 | Hava durumu sicaklik eksiginde 502 doner | Servis payload'inda sicaklik yoktur | `get_current_weather` cagrilir | `Hava durumu yaniti eksik` hatasi doner | Gecti |
| BUT-22 | Hava durumu servis hatasinda 503 doner | `urlopen` hata firlatir | `get_current_weather` cagrilir | Servis gecici kullanilamiyor hatasi doner | Gecti |
| BUT-23 | Geocode basarili ilk sonucu doner | Geocoding API sonucu mock'lanmistir | `_geocode_city` cagrilir | Latitude, longitude ve gorunen sehir doner | Gecti |
| BUT-24 | Geocode sonuc yoksa temiz sehir adini doner | API `results=[]` doner | `_geocode_city` cagrilir | Koordinatlar `None`, sehir adi temiz doner | Gecti |
| BUT-25 | Admin kullanici yetki kontrolunden gecer | `_is_user_admin=True` mock'lanir | `_require_admin` cagrilir | Hata firlatilmaz | Gecti |
| BUT-26 | Admin olmayan kullanici 403 alir | `_is_user_admin=False` mock'lanir | `_require_admin` cagrilir | `Admin yetkisi gerekli` hatasi doner | Gecti |
| BUT-27 | Room id yoksa oda dogrulamasi DB sorgulamaz | `room_id=None` verilir | `_validate_room_for_user` cagrilir | DB query cagrilmaz | Gecti |
| BUT-28 | Kullaniciya ait olmayan oda 404 doner | DB oda bulamaz | `_validate_room_for_user` cagrilir | `Oda bu kullaniciya ait degil` hatasi doner | Gecti |
| BUT-29 | Studio setup paketi oda/cihaz/sensor olusturur | Kullanici henuz configure edilmemistir | `_create_setup_package` cagrilir | 3 oda, 4 cihaz, 5 sensor sonucu doner | Gecti |
| BUT-30 | Gecersiz setup paketi 400 doner | Paket id bilinmiyor | `_create_setup_package` cagrilir | `Gecersiz paket` hatasi doner | Gecti |
| BUT-31 | Kurulumu yapilmis kullanici setup tekrarinda 409 alir | Room count 1 doner | `_create_setup_package` cagrilir | Conflict hatasi doner | Gecti |
| BUT-32 | Cihaz kontrolu cihazi acar | Cihaz vardir ve kapali durumdadir | `send_control_command(turn_on)` cagrilir | Status `True`, response `ok` olur | Gecti |
| BUT-33 | Cihaz kontrolu cihazi kapatir | Cihaz vardir ve acik durumdadir | `send_control_command(turn_off)` cagrilir | Status `False` olur | Gecti |
| BUT-34 | Olmayan cihaz kontrolu 404 doner | DB cihaz bulamaz | `send_control_command` cagrilir | `Cihaz bulunamadi` hatasi doner | Gecti |
| BUT-35 | Bos chat mesaji 400 doner | Mesaj sadece bosluk icerir | `create_chat_message` cagrilir | `Mesaj bos olamaz` hatasi doner | Gecti |
| BUT-36 | Normal kullanici mesaji ilk admine gider | Admin kullanici vardir | `create_chat_message` cagrilir | Receiver admin id olur, metin trimlenir | Gecti |
| BUT-37 | Admin mesajinda hedef kullanici yoksa 400 doner | Current user admindir | `create_chat_message` cagrilir | `Hedef kullanici gerekli` hatasi doner | Gecti |
| BUT-38 | Admin hedef kullaniciya mesaj yollar | Target user vardir | `create_chat_message` cagrilir | Conversation ve receiver target user olur | Gecti |
| BUT-39 | Yeni FCM token kaydedilir | Token DB'de yoktur | `register_fcm_token` cagrilir | Yeni `FCMToken` eklenir ve commit edilir | Gecti |
| BUT-40 | Var olan FCM token guncellenir | Token DB'de vardir | `register_fcm_token` cagrilir | `updated_at` set edilir, yeni kayit eklenmez | Gecti |
| BUT-41 | FCM token DB hatasinda rollback ve 500 doner | DB query hata firlatir | `register_fcm_token` cagrilir | Rollback olur ve 500 hatasi doner | Gecti |
| BUT-42 | Health endpoint running doner | On kosul yok | `health` cagrilir | `{"status": "running"}` doner | Gecti |
| BET-01 | Health endpoint contract running doner | On kosul yok | `health` route fonksiyonu cagrilir | `{"status": "running"}` doner | Gecti |
| BET-02 | `/me` current user claims ile kullanici doner | Claims icinde user id ve email vardir | `get_me` route fonksiyonu cagrilir | Kullanici email ve admin bilgisi doner | Gecti |
| BET-03 | Chat mesaj endpoint'i bos metni reddeder | Mesaj sadece bosluk icerir | `create_chat_message` route fonksiyonu cagrilir | 400 `Mesaj bos olamaz` doner, commit edilmez | Gecti |
| BET-04 | Admin chat listeleme hedef kullanici ister | Current user admindir, hedef yoktur | `list_chat_messages` cagrilir | 400 `Hedef kullanici gerekli` doner | Gecti |
| BET-05 | Control endpoint olmayan cihazi commit etmeden reddeder | DB cihaz bulamaz | `send_control_command` route fonksiyonu cagrilir | 404 `Cihaz bulunamadi` doner, commit edilmez | Gecti |
| BET-06 | Admin users endpoint admin olmayan kullaniciyi reddeder | Kullanici admin degildir | `list_users` cagrilir | 403 `Admin yetkisi gerekli` doner | Gecti |
| BET-07 | FCM token endpoint yeni token olusturur | Token DB'de yoktur | `register_fcm_token` route fonksiyonu cagrilir | Token eklenir ve commit edilir | Gecti |
| BET-08 | Control endpoint mevcut cihazi acar | Cihaz DB'de vardir ve kapali durumdadir | `send_control_command(turn_on)` cagrilir | Status true olur ve commit edilir | Gecti |
| BET-09 | Setup status endpoint kurulum sayaclarini doner | `_setup_counts` mock'lanmistir | `get_setup_status` cagrilir | Oda/cihaz/sensor sayilari doner | Gecti |
| BMT-01 | MQTT sensor mesaji DB'ye kaydedilir | Gecerli MQTT JSON payload vardir | `on_message` cagrilir | `SensorReading` eklenir, commit ve close cagrilir | Gecti |
| BMT-02 | Bozuk MQTT JSON session acmadan yok sayilir | Payload JSON degildir | `on_message` cagrilir | DB session acilmaz | Gecti |

Son dogrulama:

- `./venv/bin/python -m unittest discover -s backend/tests -p "test_*.py"`: `53 tests passed`
