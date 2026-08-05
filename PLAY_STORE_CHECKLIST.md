# PLAY STORE CHECKLIST — BB Block

**Tarih:** 2026-08-05 · Bu denetim boyunca gerçekten doğrulanan maddeler ✅, kullanıcı aksiyonu
bekleyenler ⚠️, henüz hiç ele alınmamış (bu denetimin kapsamı dışında) maddeler ⬜ olarak işaretli.

## Teknik Altyapı

- ✅ **Release signing** — `android/eyegames-upload-keystore.jks` + `key.properties` kurulu, gitignore'lu, `apksigner verify` ile doğrulanmış (önceki oturumda).
- ✅ **R8/ProGuard/minify/shrinkResources** — bu oturumda açıldı, GERÇEK bir release build + emülatör smoke-test ile doğrulandı.
- ✅ **Dart obfuscation (`--obfuscate --split-debug-info`)** — gerçek bir build ile denendi ve başarılı oldu; `build/symbols/` sembolleri üretildi (bu build'e özel, her release'de yeniden üretilmeli ve arşivlenmeli).
- ✅ **Android izinleri minimal** — release manifestinde dangerous permission yok (Aşama 4'te doğrulandı).
- ⚠️ **`applicationId` hâlâ `com.bbblock.bb_block` placeholder'ı** — gerçek ters-domain gerekli, Play Console'da bir kez seçilince DEĞİŞTİRİLEMEZ, dikkatli seçilmeli.
- ⚠️ **minSdk/targetSdk/compileSdk `flutter.*` üzerinden geliyor** — bu KASITLI ve doğru (Flutter'ın kendi konvansiyonu), ama Codemagic'te (Aşama 12) Flutter SDK sürümünün kendisinin pinlenmesi gerekiyor.

## Reklam / Üçüncü Parti SDK

- ⚠️ **AdMob App ID + ad-unit ID'leri hâlâ Google'ın test değerleri** — `AndroidManifest.xml`, `admob_ads_service.dart`. AdMob console'undan gerçek ID gerekli. **Bu, Play Store incelemesinin reddedebileceği en somut engel.**
- ✅ **`purchases_flutter` (RevenueCat) kullanılmıyor ama zararsız** — pubspec'te duruyor, hiçbir API çağrısı yok, mağaza incelemesini etkilemez (kullanılmayan bir bağımlılık, davranışsal bir risk değil).

## Store Listing (bu denetimin kapsamı dışında — ayrıca hazırlanmalı)

- ⬜ Ekran görüntüleri (telefon + tablet, gerekli boyutlarda)
- ⬜ Feature graphic (1024x500)
- ⬜ Kısa/uzun açıklama metni
- ⬜ Kategori seçimi, içerik derecelendirmesi anketi
- ⬜ Gizlilik politikası URL'si (eyegames.net'te zaten var: `/gizlilik-politikasi` — Play Console'a bağlanmalı)
- ⬜ Veri güvenliği formu (Play Console'un kendi "Data safety" bölümü — AdMob/Supabase'in topladığı veri türleri beyan edilmeli)

## Gönderim Öncesi Son Kontrol

1. Gerçek AdMob ID'lerini gir, `flutter build appbundle --release --obfuscate --split-debug-info=<yol>` ile AAB üret.
2. `build/symbols/`'ı release sürüm numarasıyla eşleşecek şekilde arşivle (gelecekteki crash sembolikasyonu için).
3. Play Console'da "Internal testing" track'ine yükleyip gerçek bir cihazda son bir kez test et.
4. Data safety formunu doldur (AdMob + Supabase'in `ad_views` telemetrisi dahil).
5. `com.bbblock.bb_block` yerine gerçek `applicationId`'yi Play Console'a kaydetmeden önce SON KEZ teyit et — geri dönüşü yok.
