# Build Pipeline — BB Block

**Tarih:** 2026-08-05 · `codemagic.yaml`'daki her adımın NEDEN o sırada olduğunun teknik gerekçesi.

## Pipeline Sırası (her workflow için ortak ilk 4 adım)

```
1. flutter pub get
2. dart run build_runner build --delete-conflicting-outputs   (freezed/json_serializable/riverpod codegen)
3. flutter analyze
4. flutter test
5. [workflow'a özel] build apk/appbundle/ipa
6. [yalnızca release workflow'ları] publish
```

**Neden bu sıra?** Codegen (`build_runner`) önce çalışmalı çünkü `flutter analyze`/`flutter test`
üretilen `.freezed.dart`/`.g.dart` dosyalarına bağımlı — bunlar olmadan analiz/test adımları
başarısız olur (bu proje `.freezed.dart`/`.g.dart`'ı gitignore'luyor, her build'de yeniden üretilmesi
gerekiyor, tıpkı bu denetim boyunca lokal olarak her seferinde yapıldığı gibi). Test/analiz, GERÇEK
build'den önce çalışmalı — bozuk bir build'i imzalamak/yayınlamak için zaman harcamamak için erken
başarısız olmalı ("fail fast").

## Sürüm Numaralandırma Pipeline'ı

```
git tag v1.0.0+1 (developer, manuel)
        ↓
CM_TAG = "v1.0.0+1" (Codemagic otomatik sağlıyor)
        ↓
--build-name="${CM_TAG#v}" → "1.0.0+1" (bash'in `#` prefix-strip operatörü, "v" öneki kesilir)
        ↓
--build-number="$PROJECT_BUILD_NUMBER" (Codemagic'in kendi otomatik-artan sayacı — VERSIONING_GUIDE.md'nin "Automatic Build Number" gereksinimi böyle karşılanıyor)
```

## Signing Pipeline'ı (Android)

```
Codemagic dashboard'a yüklenen .jks (bb_block_keystore referansı)
        ↓
android_signing: [bb_block_keystore] → Codemagic bunu decode edip CM_KEYSTORE_PATH/
CM_KEYSTORE_PASSWORD/CM_KEY_ALIAS/CM_KEY_PASSWORD env var'larını inject ediyor
        ↓
"Write android/key.properties" script adımı bu değişkenlerden bir key.properties dosyası üretiyor
        ↓
android/app/build.gradle.kts (bu repo'da ZATEN VAR, HİÇ DEĞİŞTİRİLMEDİ) bu dosyayı okuyup
signingConfigs.release'i kuruyor — CI'daki ve geliştiricinin lokalindeki signing mantığı AYNI kod yolu
```

**Bu tasarımın avantajı**: `build.gradle.kts`'e Codemagic'e özel hiçbir kod eklenmedi — CI'a özel
kısım tamamen `codemagic.yaml`'da izole. Bir geliştirici lokalinde kendi `key.properties`'iyle
çalışırken de, Codemagic CI'da onun yerine YAZILAN `key.properties`'le de, AYNI Gradle mantığı
çalışıyor.

## Artifact Pipeline'ı

Her release build'i üç şey üretir: (1) imzalı AAB/IPA — mağazaya giden asıl paket, (2) `mapping.txt`
(Android, R8'in obfuscation haritası) — crash raporlarını okunabilir kılmak için Play Console'a ayrıca
yüklenmeli, (3) `build/symbols/*.symbols` (Dart obfuscation sembolleri) — gelecekteki bir crash'i
sembolikleştirmek için release'e özel arşivlenmeli. Üçü de `codemagic.yaml`'ın `artifacts:` bloğunda
listeli, Codemagic build sayfasından indirilebilir.
