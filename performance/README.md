# Performance Test Plan

Bu klasor JMeter ile calistirilacak yuk/stres testleri icin temel plani tanimlar.
Testler gercek gizli anahtar kullanmadan, ortam degiskenleri veya JMeter user
variables ile `base_url` ve `auth_token` verilerek calistirilmalidir.

## Onerilen Senaryolar

- Normal yuk: 50 kullanici, 5 dakika ramp-up, 10 dakika calisma.
- Stres testi: 200 kullanici, 10 dakika ramp-up, 10 dakika calisma.
- Izlenecek metrikler: Average, Min, Max, Throughput, Error %, 95th percentile.

## HTTP Akislari

- `GET /health`
- `GET /rooms`
- `GET /devices`
- `GET /sensor-definitions`
- `GET /sensors/latest`
- `GET /chat/messages`
- `POST /control`

## JMeter Komut Ornegi

```bash
jmeter -n \
  -t performance/smart_home_api_load_test.jmx \
  -Jbase_url=http://localhost:8000 \
  -Jauth_token=YOUR_TEST_JWT \
  -l performance/results.jtl \
  -e -o performance/report
```

`results.jtl` ve HTML rapor ciktisi versiyon kontrolune eklenmemelidir.
