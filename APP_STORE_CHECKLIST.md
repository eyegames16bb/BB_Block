# APP STORE CHECKLIST — BB Block

**Tarih:** 2026-08-05 · **Önemli dürüstlük notu**: bu denetim bir Windows makinesinde yapıldı — hiçbir
madde gerçek bir Mac/Xcode üzerinde doğrulanamadı. Android'e kıyasla bu checklist'in ✅ maddeleri
"statik olarak doğru görünüyor" anlamına geliyor, "gerçek bir archive ile kanıtlandı" değil.

## Teknik Altyapı

- ✅ **Privacy Manifest oluşturuldu** — `ios/Runner/PrivacyInfo.xcprivacy`, Xcode projesine (`project.pbxproj`) mekanik olarak bağlandı (PBXBuildFile/FileReference/Group/ResourcesBuildPhase). XML well-formedness + pbxproj brace/paren dengesi script'le doğrulandı.
- ⚠️ **Privacy Manifest'in üçüncü parti SDK'larla TAM uyumu doğrulanamadı** — bunun için Xcode'un "Generate Privacy Report" aracı (yalnızca bir gerçek `xcodebuild archive`'dan sonra, Mac'te) gerekli. AdMob/Supabase/diğer pod'ların kendi bundle ettiği manifestlerle çakışma/eksik olup olmadığı yalnızca bu araçla kesinleşir.
- ✅ **App Tracking Transparency artık doğru bağlı** (G1, bu oturumda düzeltildi) — `AdMobAdsService.init()` iOS'ta ATT iznini AdMob'dan ÖNCE istiyor. `Info.plist`'teki `NSUserTrackingUsageDescription` string'i zaten hazırdı.
- ✅ **Gerçek bir Xcode build hiç denenmedi çünkü bu makinede Xcode yok** — `flutter build ipa` bu ortamda çalıştırılamaz. **Mağaza gönderiminden önce bir Mac'te MUTLAKA denenmeli.**
- ⬜ **Dart obfuscation iOS için hiç test edilmedi** — Android'de `--obfuscate --split-debug-info` gerçek bir build ile doğrulandı, iOS eşdeğeri denenmedi.

## Reklam / Üçüncü Parti SDK

- ⚠️ **AdMob App ID hâlâ Google'ın test değeri** (`Info.plist`'teki `GADApplicationIdentifier`) — gerçek ID gerekli.
- ✅ **iOS izinleri minimal** — yalnızca `NSUserTrackingUsageDescription` var, gereksiz bir izin talebi yok (Aşama 4'te doğrulandı).

## Store Listing (bu denetimin kapsamı dışında)

- ⬜ Ekran görüntüleri (gerekli tüm cihaz boyutları — iPhone + iPad varsa)
- ⬜ App Store açıklama metni, anahtar kelimeler
- ⬜ App Store Connect'te gizlilik/veri toplama beyanı (Privacy Manifest'ten AYRI bir form — App Store Connect'in kendi "App Privacy" sorularıdır, ikisi tutarlı olmalı)
- ⬜ Yaş derecelendirmesi anketi

## Gönderim Öncesi Son Kontrol (MUTLAKA bir Mac'te yapılmalı)

1. Gerçek AdMob ID'sini `Info.plist`'e gir.
2. `flutter build ipa --release --obfuscate --split-debug-info=<yol>` çalıştır — bu denetim bunu HİÇ deneyemedi, ilk deneme sürprizlere açık olabilir (Android'de R8 ile yaşandığı gibi bir uyumluluk sorunu çıkabilir).
3. Xcode'da archive'ı aç, "Generate Privacy Report" ile üçüncü parti SDK manifestleriyle gerçek uyumu kontrol et.
4. TestFlight'a yükleyip gerçek bir cihazda test et.
5. App Store Connect'in "App Privacy" formunu `PrivacyInfo.xcprivacy` ile TUTARLI doldur.
