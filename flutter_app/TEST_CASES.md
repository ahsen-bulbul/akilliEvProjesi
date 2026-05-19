# Flutter Yazilim Testi Test Case Ozeti

## Unit Testler

Test edilen moduller: `Message`, `SensorDataModel`, `ControlDevice`.

| ID | Test Adi / Aciklama | On Kosul | Test Adimlari | Beklenen Sonuc | Durum |
| --- | --- | --- | --- | --- | --- |
| UT-01 | JSON verisi `Message` modeline donusur | Gecerli mesaj JSON'u vardir | `Message.fromJson` cagrilir | id, sender, receiver, text ve timestamp dogru map edilir | Gecti |
| UT-02 | `receiver_id` null ise bos metin kullanilir | `receiver_id` null gelir | `Message.fromJson` cagrilir | `receiverId` bos string olur | Gecti |
| UT-03 | API sensor JSON'u modele map edilir | `data` alanli sensor JSON'u vardir | `SensorDataModel.fromJson` cagrilir | sensor degerleri ve vektorler dogru okunur | Gecti |
| UT-04 | Cache map donusumu alanlari korur | Cache'e yazilacak sensor modeli vardir | `toCacheMap` ve `fromCacheMap` cagrilir | boolean, tarih ve gyro alanlari korunur | Gecti |
| UT-05 | `copyWith` status alanini degistirir | Kapali cihaz nesnesi vardir | `copyWith(status: true)` cagrilir | Diger alanlar ayni, status true olur | Gecti |
| UT-06 | `copyWith` bos cagrida status korur | Acik cihaz nesnesi vardir | `copyWith()` cagrilir | Status degismez | Gecti |

## Widget Testler

Test edilen widgetlar: `ChatBubble`, `MessageInputField`, `SensorCard`, `SmartHomeApp`.

| ID | Test Adi / Aciklama | On Kosul | Test Adimlari | Beklenen Sonuc | Durum |
| --- | --- | --- | --- | --- | --- |
| WT-01 | Kullanici mesaji sagda render edilir | Kullanici mesaji vardir | `ChatBubble` pump edilir | Metin ve saat gorunur, hizalama sagdadir | Gecti |
| WT-02 | Admin mesaji solda render edilir | Admin mesaji vardir | `ChatBubble` pump edilir | Metin ve saat gorunur, hizalama soldadir | Gecti |
| WT-03 | Mesaj inputu gonder callback'ini cagirir | Input aktiftir | Metin girilir, gonder ikonuna basilir | Callback 1 kez calisir | Gecti |
| WT-04 | Sending durumunda input pasiftir | `sending: true` verilir | Widget pump edilir, butona basilir | Progress gorunur, callback calismaz | Gecti |
| WT-05 | Sensor karti temel bilgileri gosterir | Normal sensor degeri vardir | `SensorCard` pump edilir | Etiket, deger, birim ve ikon gorunur | Gecti |
| WT-06 | Alarm durumunda uyari ikonu gosterilir | `isAlert: true` verilir | `SensorCard` pump edilir | Uyari ikonu gorunur | Gecti |
| WT-07 | Supabase ayari yoksa config mesaji gosterilir | Dart define verilmemistir | `SmartHomeApp` pump edilir | Eksik Supabase mesaji gorunur | Gecti |

## Integration Testler

Test edilen akis: mesaj yazma, sensor alarm UI davranislari ve uygulama config baslangici.

| ID | Test Adi / Aciklama | On Kosul | Test Adimlari | Beklenen Sonuc | Durum |
| --- | --- | --- | --- | --- | --- |
| IT-01 | Mesaj yazma akisi metni kabul eder | Mesaj input ekrani aciktir | Metin girilir, gonder ikonuna basilir | Girilen metin callback tarafindan alinmis olur | Gecti |
| IT-02 | Sensor alarm akisi uyari ikonunu gosterir | Alarm karti aciktir | Alert sensor karti render edilir | Uyari ikonu gorunur | Gecti |
| IT-03 | Mesaj gonderme yuklenme durumunu gosterir | `sending: true` verilir | Input render edilir | Progress gorunur ve TextField pasif olur | Gecti |
| IT-04 | Eksik Supabase config uyarisi gosterilir | Dart define verilmemistir | `SmartHomeApp` baslatilir | Config eksik mesaji gorunur | Gecti |

## Calistirma Komutlari

```bash
flutter pub get
flutter analyze
flutter test
flutter test integration_test/chat_flow_test.dart
```

Son dogrulama:

- `flutter analyze`: `No issues found!`
- `flutter test`: `13 tests passed`
- `flutter test integration_test/chat_flow_test.dart`: `4 tests passed`
