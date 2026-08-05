# Codemagic Setup — BB Block

**Tarih:** 2026-08-05 · Bu proje Codemagic ile build alınıp yayınlanacak. Bu doküman, sıfırdan bir
Codemagic hesabı/uygulaması bağlarken izlenecek adımları anlatır.

## Önemli: `codemagic.yaml`'ın gerçek konumu

Kullanıcının orijinal talebi `release/codemagic.yaml` istiyordu, ama **Codemagic'in kendi otomatik
tanıma mekanizması `codemagic.yaml`'ın Git reposunun KÖKÜNDE olmasını zorunlu kılıyor** — bir alt
klasörde olursa Codemagic dashboard'u onu görmez, manuel yapılandırma gerekir (tam olarak talebin
istediği "hiçbir manuel ayar gerektirmeyecek hale getir" hedefinin tersi). Bu yüzden gerçek, işlevsel
dosya **repo kökünde** (`codemagic.yaml`, bu dosyanın iki üst klasöründe) — `release/` altında ayrı bir
kopya OLUŞTURULMADI, çünkü iki dosyayı senkron tutmak gereksiz bir sürüklenme riski yaratırdı (biri
gerçek/kullanılan, diğeri ölü/kullanılmayan kod olurdu). Bu, denetimin daha önceki bulgularında da
(A8/A9) izlenen aynı prensip: gerçek teknik gereksinim, literal dosya yolu talebinden önce gelir.

**Git repo kökü**: `C:\Users\Baskan\VsCodeProject\BB Block` (Flutter projesinin kendisi `app/`
alt klasöründe yaşıyor — `eyegames.net` TAMAMEN ayrı, bağımsız bir Git reposu, bu Codemagic
kurulumunun kapsamında değil).

## Adım Adım Kurulum

1. **Codemagic hesabı oluştur / giriş yap** (codemagic.io) — GitHub/GitLab/Bitbucket hesabınla bağlan.
2. **Uygulama ekle**: bu repoyu (BB Block) Codemagic'e bağla. Codemagic kök dizindeki `codemagic.yaml`'ı
   otomatik algılayacak — **manuel bir "Flutter App" sihirbazı çalıştırmana gerek yok**, bu tam olarak
   `codemagic.yaml`'ın amacı.
3. **Ortam değişkeni grupları oluştur** (Team settings → Environment variables) — tam liste ve her
   grubun içermesi gereken değişkenler: `docs/ENVIRONMENT_VARIABLES.md`. Üç grup gerekiyor:
   `bb_block_secrets`, `bb_block_google_play`, `bb_block_app_store_connect`.
4. **Android keystore'u yükle** (Team settings → Code signing identities → Android keystores) —
   referans adı `bb_block_keystore` olmalı (`codemagic.yaml`'daki `android_signing` bloğuyla eşleşmeli).
   Yüklenecek dosya: `app/android/eyegames-upload-keystore.jks` (bu repo'da zaten var, gitignore'lu —
   Codemagic'e YALNIZCA dashboard üzerinden, dosya olarak yüklenmeli, asla Git'e commit edilmemeli).
5. **iOS signing kur** (Team settings → Code signing identities → iOS) — App Store Connect API
   entegrasyonu (bkz. adım 6) otomatik provisioning profile yönetimini mümkün kılıyor, manuel
   sertifika/profil yüklemeye GEREK KALMAYABİLİR (Codemagic'in "automatic code signing" özelliği).
6. **Google Play + App Store Connect publishing entegrasyonlarını bağla** — detaylar
   `docs/STORE_DEPLOYMENT.md`.
7. **İlk build'i tetikle**: `debug-workflow` herhangi bir push'ta otomatik çalışır — bunu ilk doğrulama
   olarak kullan (signing/publishing gerektirmiyor, yalnızca "kod derleniyor mu, testler geçiyor mu"
   kontrolü).
8. **Release workflow'larını tetiklemek için**: bir `v*` formatında git tag push et (ör. `v1.0.0+1`) —
   hem `android-release` hem `ios-release` aynı tag'le tetiklenir.

## Doğrulama Sınırı (dürüstçe belirtilmeli)

Bu denetim `codemagic.yaml`'ı GERÇEK bir Codemagic hesabında ÇALIŞTIRAMADI — böyle bir hesap/erişim bu
oturumun kapsamında yoktu. `debug-workflow` ve `android-release`'in script adımları, bu denetim
sırasında AYNI komutların lokal olarak (bu makinede) gerçekten çalıştırılıp doğrulandığı komutlarla
BİREBİR aynı (`flutter build apk/appbundle --release --obfuscate --split-debug-info`, `flutter
analyze`, `flutter test`) — yani komutların KENDİSİ kanıtlanmış durumda. Ama Codemagic'in kendi
YAML şema doğrulaması, keystore/signing entegrasyonunun gerçek davranışı, ve `ios-release` (bu makinede
hiç Xcode olmadığı için hiç denenmemiş) yalnızca gerçek bir Codemagic build'inde teyit edilebilir.
İlk gerçek build'in loglarını dikkatle okumak gerekiyor.
