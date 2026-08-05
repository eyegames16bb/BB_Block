# Store Deployment — BB Block (Codemagic Publishing)

**Tarih:** 2026-08-05 · `codemagic.yaml`'ın `publishing:` bloklarının nasıl kurulacağı. Genel mağaza
gönderim süreci için `STORE_SUBMISSION_GUIDE.md`'ye bakın — bu doküman yalnızca Codemagic'in
OTOMASYON tarafını anlatıyor.

## Google Play Publisher Hazırlığı

1. Google Play Console → Setup → API access → "Create new service account" (Google Cloud Console'a
   yönlendirir).
2. Google Cloud Console'da service account oluştur, bir JSON key indir.
3. Play Console'a geri dön, yeni service account'a "Release manager" (veya en az AAB yükleme +
   internal testing yayınlama) izni ver.
4. JSON key'in TAM içeriğini Codemagic'te `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` env var'ına yapıştır
   (`bb_block_google_play` grubu, bkz. `docs/ENVIRONMENT_VARIABLES.md`).
5. `codemagic.yaml`'daki `publishing.google_play.track: internal` — ilk otomatik yayın her zaman
   Internal Testing'e gider, production'a ASLA otomatik geçmez (kasıtlı, bkz. `docs/CI_CD_GUIDE.md`).

## App Store Connect API Hazırlığı

1. App Store Connect → Users and Access → Integrations → App Store Connect API.
2. Yeni bir API anahtarı oluştur, rolü en az "App Manager" olmalı (TestFlight yükleme + build yönetimi
   için).
3. Issuer ID, Key ID'yi not al; `.p8` dosyasını indir (yalnızca BİR KEZ indirilebilir).
4. Üçünü de Codemagic'e `bb_block_app_store_connect` grubuna gir.
5. `codemagic.yaml`'daki `publishing.app_store_connect.auth: integration` bu API anahtarını kullanıyor
   — Apple ID + parola + app-specific password YÖNTEMİ KULLANILMIYOR (daha güvenli, 2FA'dan bağımsız,
   CI için önerilen resmi yöntem).

## Otomatik vs. Manuel Adımlar (net ayrım)

| Adım | Otomatik mi? |
|---|---|
| Build + imzalama + minify/obfuscate | ✅ Tamamen otomatik (tag push'unda) |
| Google Play Internal Testing'e yükleme | ✅ Otomatik |
| TestFlight'a yükleme | ✅ Otomatik |
| Production'a terfi (her iki mağaza) | ❌ Manuel — bilinçli karar, `POST_RELEASE_CHECKLIST.md` |
| Store listing içeriği (ekran görüntüleri, açıklama) | ❌ Manuel, bir kez kurulur, Codemagic'in kapsamı dışı |
| Gerçek AdMob ID'leri / applicationId / Bundle ID | ❌ Manuel — `KNOWN_LIMITATIONS.md`'deki bekleyen kullanıcı aksiyonları |

## İlk Gerçek Deployment Denemesi İçin Uyarı

Bu doküman ve `codemagic.yaml`, Codemagic'in resmi dokümantasyonuna göre doğru yapılandırıldı, ama
**hiçbiri gerçek bir Codemagic hesabında/gerçek publishing kimlik bilgileriyle test edilmedi** (bu
oturumun kapsamında böyle bir erişim yoktu). İlk gerçek `android-release`/`ios-release` çalıştırması,
özellikle publishing adımlarında, dikkatle izlenmeli.
