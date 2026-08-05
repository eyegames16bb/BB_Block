# POST-RELEASE CHECKLIST — BB Block

**Tarih:** 2026-08-05 · İlk mağaza gönderiminden ve her sonraki güncellemeden SONRA yapılması
gerekenler.

## Yayından Hemen Sonra (ilk 24-48 saat)

- [ ] Play Console / App Store Connect'te inceleme durumunu takip et.
- [ ] Onaylanınca gerçek bir cihazda mağazadan indirip kurulumu test et (sideload değil, gerçek
      mağaza dağıtımı — imzalama/signing farklarını yakalayabilir).
- [ ] AdMob dashboard'unda gerçek reklam isteklerinin/gösterimlerinin geldiğini doğrula.
- [ ] eyegames.net admin panelindeki `ad_views` sayacının GERÇEK cihazlardan veri almaya başladığını
      doğrula (`/admin` — Supabase `ad_views` tablosu).
- [ ] Crash raporlarını izlemeye başla (Play Console'un "Android vitals" / App Store Connect'in
      "Crashes" sekmesi) — `mapping.txt`/`build/symbols` doğru yüklendiyse okunabilir stack trace
      gelmeli.

## İlk Hafta

- [ ] Kullanıcı yorumlarını/derecelendirmelerini takip et — oyunun kendi rate-us akışı zaten var
      (`RewardedAdScreen`), organik mağaza yorumlarıyla karışıklık olmasın diye ayrı takip edilmeli.
- [ ] Gerçek cihaz dağılımına göre performans sorunu var mı kontrol et (düşük-segment Android
      cihazlarda `PERFORMANCE_REPORT.md`'nin P5 maddesi — sürekli çalışan parçacık sistemi Ticker'ı —
      özellikle izlenmeli).
- [ ] Supabase `ad_views` tablosunda anormal/spam insert paterni var mı kontrol et (bkz.
      `SECURITY_REPORT.md` madde B2/G2 — bilinçli olarak rate-limit'siz bırakıldı, gerçek veriyle
      yeniden değerlendirilebilir).

## Her Güncelleme Sonrası

- [ ] `VERSIONING_GUIDE.md`'ye göre sürüm numarası arttı mı?
- [ ] `RELEASE_NOTES.md`'ye yeni giriş eklendi mi?
- [ ] `flutter analyze` + `flutter test` (170/170 beklenmeli, sayı değiştiyse neden bilinmeli).
- [ ] Yeni `build/symbols`/`mapping.txt` bu spesifik sürüm için arşivlendi mi?
- [ ] Geri alma gerekirse `ROLLBACK_GUIDE.md`'ye bak.
