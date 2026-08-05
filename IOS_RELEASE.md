# iOS RELEASE — BB Block

**Tarih:** 2026-08-05 · **Bu doküman Windows'ta yazıldı, hiçbir maddesi gerçek bir Mac/Xcode'da
doğrulanmadı.** Android'in aksine, buradaki her "✅" yalnızca statik/kod-seviyesi doğruluğu ifade
eder — gerçek bir archive/build denemesi HİÇ yapılamadı.

## Mevcut Durum

| Madde | Durum |
|---|---|
| Privacy Manifest (`PrivacyInfo.xcprivacy`) | ✅ Oluşturuldu, Xcode projesine bağlandı (statik doğrulama) — ⚠️ gerçek Xcode uyumu doğrulanmadı |
| App Tracking Transparency | ✅ Bu oturumda bağlandı (`AdMobAdsService.init()`), ATT AdMob'dan önce isteniyor |
| Bundle Identifier | ⚠️ `com.bbblock.bb_block` placeholder'ı — Android'deki `applicationId` ile aynı sorun |
| AdMob App ID | ⚠️ Hâlâ Google'ın test değeri (`Info.plist`'teki `GADApplicationIdentifier`) |
| Release signing | ⬜ Bu denetimin kapsamında incelenmedi (Android tarafı gibi bir keystore/provisioning profile denetimi yapılmadı — Apple Developer hesabı/sertifikaları gerektirir) |
| Orientation | ⚠️ Hem portrait hem landscape açık (`Info.plist`) — portrait-only kilit bir ürün kararı, teknik zorunluluk değil (A13) |
| `UIBackgroundModes` | ✅ Bilinçli olarak yok — ses sistemi `AVAudioSessionCategory.ambient` kullanıyor (arka planda ses KESİLMELİ, bu doğru davranış) |

## Build Komutu (HİÇ DENENMEDİ — bir Mac'te ilk deneme sürprizlere açık olabilir)

```bash
cd app
flutter build ipa --release --obfuscate --split-debug-info=build/symbols
```

Android'de R8 ilk denemede beklenmedik bir hatayla başarısız olmuştu (Play Core sınıfları) — iOS
tarafında da benzer, önceden görülmemiş bir uyumluluk sorunu çıkma ihtimali göz ardı edilmemeli.

## Mağaza Gönderiminden Önce Bir Mac'te Yapılması Gerekenler

1. `flutter build ipa` komutunu ilk kez gerçekten çalıştır, çıkan hataları (varsa) çöz.
2. Xcode Organizer'da archive'ı aç, "Generate Privacy Report" ile üçüncü parti SDK'ların (AdMob,
   Supabase, vb.) kendi bundle ettiği manifestlerle bu projenin `PrivacyInfo.xcprivacy`'sinin GERÇEKTEN
   uyumlu olduğunu doğrula.
3. Gerçek bir Apple Developer hesabıyla signing/provisioning profile kur (bu denetimin kapsamı dışı).
4. Bundle Identifier'ı gerçek değere çevir.
5. Gerçek AdMob App ID'yi gir.
6. TestFlight'a yükleyip gerçek bir iOS cihazda test et.
