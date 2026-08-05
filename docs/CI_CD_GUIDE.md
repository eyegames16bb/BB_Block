# CI/CD Guide — BB Block

**Tarih:** 2026-08-05 · `codemagic.yaml`'daki üç workflow'un ne zaman/nasıl tetiklendiğinin genel
akış anlatımı. Tam YAML referansı için `codemagic.yaml`'ın kendisi (kapsamlı yorumlarla yazıldı).

## Üç Workflow

| Workflow | Tetikleyici | Ne yapar | Yayınlar mı? |
|---|---|---|---|
| `debug-workflow` | `main` DIŞINDAKİ her branch'e push + her PR | pub get → codegen → analyze → test → debug APK build | Hayır |
| `android-release` | `v*` git tag | Aynı + minify/obfuscate edilmiş, imzalı AAB | Evet — Google Play Internal Testing |
| `ios-release` | `v*` git tag (Android'le AYNI tag) | Aynı + minify/obfuscate edilmiş, imzalı IPA | Evet — TestFlight |

## Tipik Akış

1. Geliştirici bir feature branch'te çalışır, push eder → `debug-workflow` otomatik tetiklenir,
   birkaç dakika içinde "derleniyor mu, testler geçiyor mu" geri bildirimi verir.
2. PR açılır → aynı workflow PR üzerinde de çalışır (branch_patterns `main` hariç her şeyi kapsıyor,
   `pull_request` event'i de tetikleyiciler arasında).
3. `main`'e merge edildikten sonra, release'e hazır olunca: `VERSIONING_GUIDE.md`'ye göre
   `pubspec.yaml`'daki version güncellenir, bir git tag oluşturulup push edilir (ör. `git tag v1.0.0+1
   && git push origin v1.0.0+1`).
4. Tag push'u HEM `android-release` HEM `ios-release`'i tetikler — iki platform aynı anda, aynı
   kod durumundan build edilir (versiyon tutarlılığı garanti).
5. Android → Google Play Internal Testing'e, iOS → TestFlight'a otomatik yüklenir (`submit_as_draft`/
   `submit_to_testflight` — production'a otomatik geçiş YOK, bu kasıtlı, insan onayı olmadan gerçek
   kullanıcılara gitmemeli).
6. `POST_RELEASE_CHECKLIST.md`'ye göre manuel doğrulama yapılır, sonra Play Console/App Store
   Connect'ten elle production'a terfi ettirilir.

## Neden `main` push'u DEĞİL de tag release'i tetikliyor?

`main`'e her merge'de otomatik mağaza yayını YAPILMAMALI — bu, kontrolsüz, geri alınması zor bir
akış olurdu (bkz. `ROLLBACK_GUIDE.md`'nin "mobil rollback yavaş/sınırlı" notu). Tag-tabanlı tetikleme,
"hangi commit'in yayınlandığı" sorusuna her zaman net bir cevap verir (git tag = release kaydı) ve
release kararının bilinçli, ayrı bir adım (tag oluşturma) olmasını sağlar.

## Cache Optimizasyonu

Codemagic, `flutter: stable` + standart Flutter proje yapısı algıladığında Flutter SDK'sını ve
`.pub-cache`'i otomatik önbelleğe alır (Codemagic'in kendi platform davranışı, `codemagic.yaml`'da
elle bir `cache:` bloğu tanımlamaya GEREK YOK standart durumda) — bu, her build'de sıfırdan `flutter
pub get` indirmesini önler. Gradle/CocoaPods bağımlılıkları da benzer şekilde Codemagic'in build
makinelerinde varsayılan olarak önbelleklenir.
