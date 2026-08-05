# STORE CHECKLIST — BB Block (Birleşik)

**Tarih:** 2026-08-05 · Platform-özel detaylar için `PLAY_STORE_CHECKLIST.md`/`APP_STORE_CHECKLIST.md`
(Aşama 10) ve `ANDROID_RELEASE.md`/`IOS_RELEASE.md` (Aşama 11). Bu dosya HER İKİ mağaza için de ortak
olan, "ikisinden biri eksikse gönderim yapma" maddelerinin tek bir hızlı-kontrol listesi.

## Gönderim Öncesi Ortak Engelleyiciler

- [ ] Gerçek AdMob App ID + ad-unit ID'leri (her iki platformda da hâlâ test değerleri)
- [ ] Gerçek `applicationId`/Bundle Identifier (her iki platformda da hâlâ `com.bbblock.bb_block`)
- [ ] `flutter analyze` temiz, `flutter test` 170/170 geçiyor (bu oturumda doğrulandı, her yeni
      değişiklikten sonra tekrar çalıştırılmalı)
- [ ] Gizlilik politikası URL'si her iki mağaza konsoluna da girildi (`eyegames.net/gizlilik-politikasi`)
- [ ] Data safety / App Privacy formları dolduruldu (AdMob + Supabase `ad_views` telemetrisi beyan
      edilmeli)

## Yalnızca Android

- [ ] R8/minify/obfuscate açık release build alındı (`ANDROID_RELEASE.md`)
- [ ] `mapping.txt` + `build/symbols/` arşivlendi

## Yalnızca iOS

- [ ] Gerçek bir Mac'te `flutter build ipa` denendi (bu denetim hiç deneyemedi)
- [ ] Xcode Privacy Report ile üçüncü parti SDK uyumu doğrulandı
- [ ] Apple Developer signing/provisioning kuruldu

## Mağaza İncelemesi Sık Red Sebepleri (bu proje özelinde kontrol edilmiş olanlar)

- ✅ Test/placeholder reklam ID'leriyle gönderim — bu denetim tespit etti, kullanıcı aksiyonu bekliyor
- ✅ Eksik Privacy Manifest (iOS) — bu oturumda düzeltildi
- ✅ ATT izni istenmeden tracking SDK'sı başlatma (iOS) — bu oturumda düzeltildi
- ✅ Gereksiz izin talepleri — Aşama 4'te taranıp temiz bulundu
- ⬜ Store listing içeriğinin kendisi (ekran görüntüleri, açıklama) — bu denetimin kapsamı dışı
