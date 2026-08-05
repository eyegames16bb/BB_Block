# Environment Variables — BB Block (Codemagic)

**Tarih:** 2026-08-05 · `codemagic.yaml`'ın referans verdiği üç env var grubunun (Codemagic dashboard'da
Team settings → Environment variables altında oluşturulmalı) TAM içeriği. **Hiçbir gerçek secret
değeri bu repoda YOK** — yalnızca hangi değişkenin hangi grupta olması gerektiği.

## Grup: `bb_block_secrets`

| Değişken | Açıklama | Kaynak |
|---|---|---|
| `SUPABASE_URL` | BB Block'un `ad_views` telemetrisi için kullandığı Supabase proje URL'i | Supabase dashboard → Project Settings → API |
| `SUPABASE_ANON_KEY` | Aynı proje için anon (public) key — RLS `anon` rolüne yalnızca `ad_views` INSERT izni veriyor (Aşama 1/4'te doğrulandı) | Supabase dashboard → Project Settings → API |

Bu ikisi `--dart-define=SUPABASE_URL=...`/`--dart-define=SUPABASE_ANON_KEY=...` olarak build
komutlarına geçiriliyor — `lib/core/config/supabase_config.dart`'ın zaten beklediği format (bkz.
CLAUDE.md'nin "Supabase gerçek bir entegrasyona döndü" maddesi).

## Grup: `bb_block_google_play`

| Değişken | Açıklama | Kaynak |
|---|---|---|
| `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` | Google Play Developer API'ye erişimi olan bir service account'un JSON kimlik bilgisi (tam dosya içeriği, Codemagic'in "secure" tipi env var olarak) | Google Play Console → API access → yeni bir service account oluştur, gerekli izinleri ver (release management) |

## Grup: `bb_block_app_store_connect`

| Değişken | Açıklama | Kaynak |
|---|---|---|
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect API anahtarının issuer ID'si | App Store Connect → Users and Access → Integrations → App Store Connect API |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | API anahtarının kendi ID'si | Aynı yer |
| `APP_STORE_CONNECT_PRIVATE_KEY` | `.p8` anahtar dosyasının içeriği | Aynı yer — yalnızca BİR kez indirilebilir, kaybedilirse yeni bir anahtar oluşturulmalı |

## `android_signing`/`ios_signing` — bunlar env var GRUBU değil, ayrı bir mekanizma

`android_signing: [bb_block_keystore]` ve `ios_signing:` bloğu Codemagic'in "Code signing identities"
bölümünden gelir — yukarıdaki üç gruptan FARKLI bir dashboard alanı. `docs/CODEMAGIC_SETUP.md`'nin
4-5. adımlarına bakın.

## Neden `flutter: stable` / `xcode: latest` — sabit bir sürüm numarası değil?

- `flutter: stable`: Bu denetim `flutter --version`'ı `3.44.7` olarak doğruladı (2026-08-05 itibariyle),
  ama bu sayıyı `codemagic.yaml`'a HARDCODE ETMEK, Flutter'ın kendi güncellemeleriyle zamanla
  eskiyecek bir bakım yükü yaratırdı. `stable` kanalı, Codemagic'in her build'de o an güncel stabil
  sürümü kullanmasını sağlıyor — Flutter'ın SDK sürüm kısıtı zaten `pubspec.yaml`'da (`sdk: ^3.8.1`)
  var, asıl reproducibility garantisi ORADAN geliyor.
- `xcode: latest`: Bu makinede (Windows) hiç Xcode olmadığı için "şu an güncel Xcode sürümü nedir"
  gerçekten doğrulanamadı — sahte bir kesinlikle yanlış bir sürüm numarası yazmak yerine dürüstçe
  `latest` kullanıldı. Kullanıcı belirli bir Xcode sürümüne ihtiyaç duyarsa (ör. belirli bir iOS SDK
  özelliği için) bu satır `xcode: 16.2` gibi kesin bir değere çevrilebilir.
- `java: 17`: Bu SABİTLENDİ çünkü somut bir gerekçesi var — AGP 8.7.3 (bu repo'nun kendi
  `android/settings.gradle.kts`'inde pinli) Gradle'ı çalıştırmak için JDK 17 gerektiriyor, bu
  tahmine dayalı değil, AGP'nin kendi dokümante edilmiş gereksinimi.
