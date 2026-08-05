# RELEASE GUIDE — BB Block

**Tarih:** 2026-08-05 · Bu oturumda gerçek komutlarla doğrulanan release akışı. Codemagic
otomasyonuyla (Aşama 12, henüz başlanmadı) bu adımlar CI'a taşınacak — o zamana kadar manuel akış budur.

## Android — Release APK/AAB

```bash
cd app
flutter pub get
dart run build_runner build
flutter analyze
flutter test

# APK (sideload/test için):
flutter build apk --release --obfuscate --split-debug-info=build/symbols

# Play Store için (AAB):
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

**Bu tam komut (`--obfuscate --split-debug-info` dahil) bu oturumda gerçekten çalıştırıldı ve
doğrulandı** — ilk denemede R8 "missing classes" hatası verdi (Play Core split-install sınıfları,
`proguard-rules.pro`'ya `-dontwarn com.google.android.play.core.**` eklenerek çözüldü), ikinci
denemede 64.0MB'lık bir APK başarıyla üretildi ve emülatörde smoke-test edildi.

**Önemli**: `build/symbols/` klasörü her release'e özeldir (obfuscation mapping'i içerir) — gelecekteki
bir crash raporunu sembolikleştirmek için gerekiyorsa, o SPESİFİK release'in symbols klasörü
arşivlenmelidir (`build/` gitignore'lu, kalıcı bir yerde saklanmalı).

## iOS — Release IPA

Bu makinede Xcode olmadığı için **hiç denenmedi**. Bir Mac'te:

```bash
cd app
flutter build ipa --release --obfuscate --split-debug-info=build/symbols
```

Ardından Xcode Organizer veya `xcodebuild -exportArchive` ile App Store Connect'e yükle.

## Sürüm Numaralandırma

`pubspec.yaml`'daki `version: 1.0.0+1` — `+` öncesi `versionName`/`CFBundleShortVersionString`
(kullanıcıya görünen), `+` sonrası `versionCode`/`CFBundleVersion` (her yüklemede artmalı). Şu an
manuel — Aşama 12'de Codemagic'in otomatik build-number artırma mekanizmasına bağlanacak.

## Her Release Öncesi Kontrol Listesi

1. `flutter analyze` temiz mi?
2. `flutter test` tümü geçiyor mu? (şu an 170/170)
3. `pubspec.yaml`'daki `version` artırıldı mı?
4. AdMob ID'leri gerçek mi (hâlâ test ID'leriyse DURDUR)?
5. `key.properties`/keystore mevcut mu (release build imzasız kalır, aksi halde)?
6. Gerçek bir cihaz/emülatörde son bir smoke-test yapıldı mı?
