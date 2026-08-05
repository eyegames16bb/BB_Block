# ANDROID RELEASE — BB Block

**Tarih:** 2026-08-05 · Android'e özel release detayları. Genel akış için `RELEASE_GUIDE.md`.

## Mevcut Durum

| Madde | Durum |
|---|---|
| Signing | ✅ `android/eyegames-upload-keystore.jks` + `key.properties` (gitignore'lu), `apksigner verify` ile doğrulanmış |
| R8/ProGuard/minify/shrinkResources | ✅ Bu oturumda açıldı (`build.gradle.kts` + `proguard-rules.pro`) |
| Dart obfuscation | ✅ `--obfuscate --split-debug-info` ile gerçek build alındı, çalıştı |
| `applicationId` | ⚠️ Hâlâ `com.bbblock.bb_block` (placeholder) — Play Console'a kayıttan ÖNCE değiştirilmeli, sonra değiştirilemez |
| AdMob App ID | ⚠️ Hâlâ Google'ın test değeri (`ca-app-pub-3940256099942544~...`) |
| minSdk/targetSdk/compileSdk | ✅ `flutter.*` üzerinden — Flutter'ın kendi konvansiyonu (bilinçli, sabitlenmedi) |
| İzinler | ✅ Release manifestinde dangerous permission yok |

## Build Komutu (doğrulanmış)

```bash
cd app
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

İlk deneme R8 "missing classes" hatası verdi (`com.google.android.play.core.splitinstall.*` — Flutter
Play Feature Delivery bağımlılığı, bu proje kullanmıyor). `android/app/proguard-rules.pro`'ya
`-dontwarn com.google.android.play.core.**` eklenerek çözüldü. **Bu proje bu satırı zaten içeriyor**,
tekrar eklemeye gerek yok.

## Play Console'a Yükleme Öncesi

1. `applicationId`'yi gerçek değere çevir (`android/app/build.gradle.kts:41`).
2. Gerçek AdMob App ID'yi `AndroidManifest.xml`'e ve `admob_ads_service.dart`'a gir.
3. `build/symbols/` klasörünü bu spesifik release sürümüyle etiketleyip arşivle.
4. `mapping.txt` (`build/app/outputs/mapping/release/`) — Play Console'un "Deobfuscation files"
   bölümüne yüklenmeli (crash raporlarının okunabilir olması için).

## Bilinen Uyarılar (engelleyici değil, ileride ele alınmalı)

`flutter build` çıktısı şunları uyardı: Gradle 8.12 (Flutter 8.14.0+ öneriyor), AGP 8.7.3 (8.11.1+
öneriyor), Kotlin 2.1.0 (2.2.20+ öneriyor). Şu an build'i BOZMUYOR, ama Codemagic kurulumunda (Aşama
12) bu sürümlerin güncellenmesi düşünülmeli.
