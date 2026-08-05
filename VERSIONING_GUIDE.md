# VERSIONING GUIDE — BB Block

**Tarih:** 2026-08-05

## Şema

`pubspec.yaml`'daki `version: 1.0.0+1` — [Semantic Versioning](https://semver.org/) `MAJOR.MINOR.PATCH+BUILD`:

- **MAJOR**: geriye dönük uyumsuz büyük değişiklik (ör. save formatı değişip eski kayıtlar okunamaz hale gelirse — şu an hiç yaşanmadı, `PlayerProgress`/`SavedRound` hep geriye uyumlu genişletildi).
- **MINOR**: yeni özellik, geriye uyumlu (ör. yeni bir booster, yeni bir mod).
- **PATCH**: bug fix, davranış değişikliği yok.
- **BUILD** (`+` sonrası): her mağaza yüklemesinde ARTMALI — Android `versionCode`, iOS `CFBundleVersion`. Mağazalar aynı build numarasını iki kez kabul etmez.

## Şu Anki Durum

`1.0.0+1` — henüz hiç mağazaya gönderilmedi, ilk sürüm için makul bir başlangıç.

## Süreç

1. Her release öncesi `pubspec.yaml`'daki `version`'ı elle güncelle (Android/iOS ikisi de aynı
   `pubspec.yaml`'dan okuyor — `flutter.versionName`/`flutter.versionCode`, `FLUTTER_BUILD_NAME`/
   `FLUTTER_BUILD_NUMBER`).
2. `RELEASE_NOTES.md`'ye yeni bir giriş ekle.
3. Git tag ile eşleştir (ör. `v1.0.0+1`) — bu proje şu an git tag kullanmıyor, önerilir.

## Aşama 12 (Codemagic) için not

Kullanıcının orijinal Aşama 12 talebi "✅ Automatic Versioning" ve "✅ Automatic Build Number"
istiyor — bu, `BUILD` numarasının CI'da otomatik artırılması (ör. Codemagic'in `$BUILD_NUMBER`
değişkeni veya git commit sayısı) anlamına gelir. Şu an MANUEL — Aşama 12'de otomatikleştirilecek,
bu doküman o zaman güncellenmeli.
