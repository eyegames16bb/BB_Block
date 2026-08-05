# MASTER AUDIT REPORT — BB Block + eyegames.net

**Tarih:** 2026-08-05
**Kapsam:** İki proje — Flutter oyunu (`BB Block/app`) ve website+admin panel (`eyegames.net`)
**Durum:** AŞAMA 1 (Full Project Analysis) tamamlandı. Bu doküman, denetimin ilerleyen aşamalarında
güncellenmeye devam edecek canlı bir belgedir — her aşama tamamlandıkça ilgili bölüm eklenecek.

Bu rapor iki alt-ajan tarafından yürütülen bağımsız, salt-okunur (read-only) kod taramasının sonucudur.
Hiçbir dosya bu aşamada değiştirilmedi. Aşağıdaki bulgular, hangi düzeltmelerin hangi sırayla
yapılacağına karar vermek için temel oluşturur.

---

## Önem Derecesi Tanımları

- **CRITICAL** — Mağaza gönderimini engeller VEYA aktif olarak istismar edilebilir bir güvenlik açığı.
- **HIGH** — Yayından önce düzeltilmeli.
- **MEDIUM** — Yayından kısa süre sonra düzeltilmeli.
- **LOW** — Kozmetik / iyileştirme fırsatı, acil değil.

---

## BÖLÜM A — BB Block (Flutter Oyunu)

### CRITICAL

| # | Bulgu | Konum | Aşama |
|---|---|---|---|
| A1 | AdMob App ID'leri (Android manifest + iOS plist + `admob_ads_service.dart`'taki ad-unit ID'leri) Google'ın herkese açık **test** ID'leri — gerçek değil. | `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` (`GADApplicationIdentifier`), `lib/core/services/ads/admob_ads_service.dart:19,21` | Aşama 5 |
| A2 | Apple Privacy Manifest (`PrivacyInfo.xcprivacy`) tamamen eksik — 2024'ten beri zorunlu, App Store Connect'te en yaygın red sebeplerinden biri. | `ios/Runner/` (dosya yok) | Aşama 5 |

### HIGH

| # | Bulgu | Konum | Aşama |
|---|---|---|---|
| A3 | Android release build'de `minifyEnabled`/`shrinkResources`/R8/ProGuard hiç yapılandırılmamış — release APK/AAB minify/obfuscate edilmeden gidiyor. | `android/app/build.gradle.kts` (release build type) | Aşama 5 |

### MEDIUM

| # | Bulgu | Konum | Aşama | Durum |
|---|---|---|---|---|
| A4 | `freezed` dev_dependency'si stabil değil, bir `-dev` prerelease sürümüne sabitlenmiş (`^3.2.6-dev.1`). | `pubspec.yaml` | Aşama 2 | ✅ **Düzeltildi** — gerçek son stabil sürüm (`3.2.5`) pub.dev'de doğrulandı (`4.0.0-dev.3` de bir prerelease, stabil değil), pubspec `^3.2.5`'e sabitlendi, `flutter pub get` + `dart run build_runner build` + `flutter analyze` + `flutter test` (170/170) sorunsuz geçti. |
| A5 | minSdk/targetSdk/compileSdk açıkça sabitlenmemiş, ortamdaki Flutter SDK sürümüne bağımlı — reproducible release build riski. | `android/app/build.gradle.kts` | Aşama 5 | Bekliyor |
| A6 | `assets/images/test_ad.png` — production asset'in dosya adında "test" geçiyor. | `assets/images/test_ad.png`, kullanım: `rewarded_ad_screen.dart:128` | Aşama 2 | ✅ **Düzeltildi** — kullanıcı onayladı, `git mv` ile `assets/images/rewarded_ad_promo.png`'a taşındı, tek kod referansı güncellendi, `flutter analyze`/`flutter test` temiz. |
| A7 | `purchases_flutter` (RevenueCat) pubspec'te var ama `lib/` içinde SIFIR kullanım — ya kullanılmayan bağımlılık ya da eksik bir IAP özelliği. | `pubspec.yaml` | Aşama 2 | ⚠️ **Ertelendi** — kullanıcı karar veremedi ("bilmiyorum"). Dokunulmadı (kaldırmak geri alınması kolay olsa da yanlışlıkla planlanan bir IAP özelliğini bozmamak için varsayılan "bırak" tercih edildi). Kullanıcı netleştirince tek satırlık bir silme. |
| A8 | `intl: any` — tamamen sabitlenmemiş (unpinned) bağımlılık kısıtı. | `pubspec.yaml` | Aşama 2 | ❌ **DÜZELTME: yanlış pozitifti.** `C:\flutter\packages\flutter_localizations\pubspec.yaml` bu Flutter SDK sürümü için `intl: 0.20.2`'yi (esnek değil, TAM sabit) zorunlu kılıyor — bu, SDK'nın kendi (resmi, `flutter create` şablonunun da kullandığı) konvansiyonu: uygulama `intl`'i kendi başına sabitlerse, her Flutter SDK yükseltmesinde `flutter_localizations`'ın kendi sabit sürümüyle çakışma riski doğar. `intl: any` burada ihmal değil, doğru pratik — koda dokunulmadı. |

### LOW

| # | Bulgu | Konum | Durum |
|---|---|---|---|
| A9 | `android/app/build.gradle.kts:40` — stok Flutter şablon yorumu (`// TODO: Specify your own unique Application ID`). | | ❌ **DÜZELTME: yanlış pozitifti.** `applicationId = "com.bbblock.bb_block"` CLAUDE.md'de zaten bilinen bir **placeholder** olarak belgeli ("mağaza gönderiminden önce gerçek ters-domain ile değiştirilmeli") — yani TODO hâlâ doğru/geçerli, yanıltıcı değil. Silinmedi; gerçek applicationId değişimi Aşama 5'in (kullanıcının gerçek ters-domain'ini gerektiren) kapsamında. |
| A10 | Keystore (`eyegames-upload-keystore.jks`) ve `key.properties` başka hiçbir yerde yedeklenmiş görünmüyor — kaybedilirse uygulamanın gelecekteki güncellemeleri kalıcı olarak engellenir (operasyonel risk, kod değil). | | Bekliyor (kullanıcı aksiyonu) |
| A11 | `assets/` toplam ~13.1 MB, hepsi sıkıştırılmamış PNG — WebP'ye çevirmek boyutu düşürebilir. | | Bekliyor — Aşama 3 |
| A12 | iOS `UIBackgroundModes` yok — arkaplan ambient ses davranışının kasıtlı olduğunu doğrula. | | Bekliyor — Aşama 5 |
| A13 | iOS ekran yönü portrait+landscape hepsi açık — 10x10 tahta oyunu için portrait-only kilit tasarım açısından değerlendirilebilir (bug değil, tasarım kararı). | | Bekliyor — Aşama 5 |

### Temiz (bulgu yok, doğrulandı)

- Kod tabanında ham `print`/`debugPrint`/`developer.log` YOK, tüm loglama `appLogger` üzerinden.
- Yorum satırına alınmış ölü kod bloğu YOK.
- `.gitignore` eksiksiz (`.jks`, `key.properties`, `.env*`, generated code, build output hepsi kapsanıyor).
- Sinyaling/secrets taramasında hardcoded gerçek secret bulunamadı — Supabase URL/anon key `--dart-define` ile derleme zamanında enjekte ediliyor.
- `vibration` paketi (önceki oturumda kaldırılmıştı) pubspec'te YOK, kullanım da YOK — temizlik tam.
- Klasör yapısı (Clean Architecture / feature-first) tutarlı uygulanmış, `domain/` katmanlarında `flutter/*` import'u yok.

---

## BÖLÜM B — eyegames.net (Website + Admin Panel)

### CRITICAL

*(Bu aşamada CRITICAL seviyede bulgu YOK.)*

### HIGH

| # | Bulgu | Konum | Aşama | Durum |
|---|---|---|---|---|
| B1 | Cron endpoint'in auth kontrolü `CRON_SECRET` set edilmişse ÇALIŞIYOR — `.env.local`'da bu değer BOŞ. Vercel Production'da da boşsa, endpoint kimliksiz herkese açık hale gelir. | `app/api/cron/sync-store-stats/route.ts` | Aşama 6 | ✅ **Kod tarafı düzeltildi.** Kullanıcı Vercel Production'ı kontrol edemedi ("bilmiyorum kontrol et") ve bu asistanın Vercel CLI/API erişimi yok (`vercel` CLI kurulu değil, proje linklenmemiş) — bu yüzden Vercel dashboard'unu BEN doğrulayamıyorum, kullanıcının kendisinin kontrol etmesi gerekiyor. Bunun yerine endpoint'i Vercel'in durumundan BAĞIMSIZ güvenli hale getirdim: `CRON_SECRET` tanımsızsa artık sessizce devam etmek yerine `500` dönüyor (fail-closed — "loud failure"). Yani günlük cron job'u Vercel'de secret gerçekten set edilene kadar görünür şekilde başarısız olacak, ama artık hiçbir koşulda kimliksiz çalışamaz. **Kullanıcı aksiyonu hâlâ gerekli:** Vercel Production ortam değişkenlerinde `CRON_SECRET` set edilmeli (rastgele bir değer üretip hem Vercel'e hem gerekirse `.env.local`'a eklenmeli) — bu adımı ben yapamam, Vercel hesabına erişim gerektirir. `npx tsc --noEmit` + `npx eslint` temiz. |

### MEDIUM

| # | Bulgu | Konum | Aşama |
|---|---|---|---|
| B2 | `ad_views` tablosunun anon INSERT policy'si (`with check (true)`) hiçbir rate-limit/throttle olmadan — herkese açık anon key ile metrik kirletme (spam insert / `viewed_at` backdating) mümkün. Mimari gereği kabul edilebilir risk, ama belgelenmemiş/mitigasyonsuz. | `supabase/schema.sql:18-22` | Aşama 6 |
| B3 | Sitemap yalnızca ana sayfayı listeliyor — 3 yasal sayfa (`/gizlilik-politikasi`, `/kullanim-sartlari`, `/cerez-politikasi`) sitemap'te yok. | `app/sitemap.ts:5-13` | Aşama 7 |

### LOW

| # | Bulgu | Konum |
|---|---|---|
| B4 | Repo'da hiç otomatik test suite yok (`package.json`'da `test` script'i bile yok) — özellikle admin auth gate ve doğrulanmamış (`DOĞRULANMADI` yorumlu) store-stats entegrasyonları için. |
| B5 | `proxy.ts`'nin matcher'ı `/api/*`'ı tamamen dışarıda bırakıyor — bugün sorun değil (tek route kendi kontrolüne sahip) ama gelecekte eklenecek bir `/api/admin/*` route'u `/admin` session gate'ini otomatik miras almaz. |
| B6 | `app/manifest.ts` hem `any` hem `maskable` ikon amacı için aynı, maskable-safe padding'i olmayan tek bir ikonu tekrar kullanıyor. |
| B7 | CSP'de `style-src 'self' 'unsafe-inline'` (nonce'lanmamış) — Framer Motion/custom cursor'ın inline style kullanımı nedeniyle kasıtlı ve belgelenmiş bir gevşetme. |

### Temiz (bulgu yok, doğrulandı — beklenenden İYİ durumda)

- `.env.local` doğru şekilde git-ignore'lu ve tracked değil; hardcoded secret taramasında SIFIR sonuç.
- `ad_views` RLS'i beklenen "yalnızca anon INSERT" şeklini birebir karşılıyor; `store_stats_daily` doğru şekilde sıfır anon/authenticated policy'e sahip (yalnızca service-role).
- `/admin/*` rotaları GERÇEKTEN iki bağımsız katmanla korunuyor (`proxy.ts` + `app/admin/(protected)/layout.tsx`), ikisi de gerçek `supabase.auth.getUser()` çağırıyor, ikisi de fail-closed.
- Hardcoded admin kimlik bilgisi YOK; auth Supabase email/password, admin kullanıcılar manuel provision ediliyor.
- Güçlü, kasıtlı güvenlik header'ları zaten kurulu (HSTS, X-Frame-Options, nonce-tabanlı CSP + `strict-dynamic`, `frame-ancestors 'none'`, `object-src 'none'`) — pre-production bir site için beklenenin çok üzerinde olgun.
- TypeScript `strict: true` gerçekten aktif, SIFIR `any` kullanımı bulundu; SIFIR leftover `console.log`; SIFIR TODO/FIXME.
- Sağlam SEO/GEO temeli: tam JSON-LD graph, OG/Twitter metadata, dinamik OG görselleri, `next/font` self-hosting, yasal sayfalarda per-page metadata override, doğru robots/sitemap altyapısı (B3 hariç).

---

---

## BÖLÜM C — Aşama 3: Flutter Performance

Bir `Explore` ajanı ile `lib/` genelinde 9 kategoride tarama yapıldı (rebuild kapsamı, dispose,
`setState` sıklığı, `const`, image decode, `Opacity`/`BackdropFilter`, `Newton` parçacık sistemi,
Riverpod `ref.watch` kapsamı, `Timer`/`Future.delayed` zincirleri). `const` kullanımı ve
controller/timer/subscription dispose'ları zaten tam ve doğru bulundu (`very_good_analysis` +
mevcut disiplinli kod zaten bunu garanti ediyor) — bulgu yok.

### Düzeltilen bulgular

| # | Bulgu | Konum | Durum |
|---|---|---|---|
| P1 | **[HIGH]** `BbBlockApp` (kök widget, `MaterialApp.router`'ı saran) `PlayerProgress`'in TAMAMINI izliyordu, yalnızca `languageCode` için — uygulamanın HERHANGİ bir yerinde skor/gold key/level gibi bir alan her değiştiğinde tüm aktif ekranı köke kadar yeniden inşa ediyordu. | `lib/app.dart` | ✅ `ref.watch(...select((async) => async.value?.languageCode ?? 'tr'))` ile daraltıldı. |
| P2 | **[MEDIUM]** `_RoundOverlay` (level/oyun bitti ekranı) zafer DIŞINDAKİ her durumda (Level Failed, Classic Game Over) da bir `Newton` parçacık sistemi + kendi sürekli çalışan `Ticker`'ını mount ediyordu, hiçbir zaman bir efekt tetiklemeden. | `lib/features/game/presentation/game_screen.dart` (`_RoundOverlay`) | ✅ `Newton` artık yalnızca `_isVictory` iken sarmalanıyor; diğer durumlarda içerik doğrudan (parçacık sistemi hiç mount edilmeden) render ediliyor. |
| P3 | **[MEDIUM]** `rewarded_ad_promo.png` (1536×1024 kaynak) 320 mantıksal piksel genişliğinde gösterilirken hiçbir çözünürlük sınırlaması olmadan tam native boyutta decode ediliyordu. | `lib/features/rewarded_ad/presentation/rewarded_ad_screen.dart` | ✅ `cacheWidth` eklendi (DPR'a göre hesaplanan hedef genişlik). |
| P4 | **[LOW-MEDIUM]** `home_background.png` (3.8MB) ve `ImageBackground` (oyun ekranı + tutorial arkaplanı) tam ekranı kapladıkları hâlde `cacheWidth`/`cacheHeight` vermeden native çözünürlükte decode ediliyordu. | `lib/features/home/presentation/home_screen.dart` (`_HomeBackground`), `lib/core/theme/image_background.dart` | ✅ İkisine de `MediaQuery` tabanlı `cacheWidth`/`cacheHeight` eklendi — kırpma/`fit` davranışı DEĞİŞMEDİ, yalnızca decode boyutu ekran boyutuna indirgendi. |

**Bulunan gerçek regresyon (bu turda, test yazılırken yakalandı)**: P4'ün `home_screen.dart`
tarafı, `splash_screen_test.dart`'ı kırdı — `cacheWidth`/`cacheHeight` verilince Flutter
`Image.asset`'in `.image`'ini artık düz bir `AssetImage` değil bir `ResizeImage(AssetImage(...))`
olarak sarmalıyor; testin `find.byWidgetPredicate`'i güvenliksiz bir `as AssetImage` cast'i
yapıyordu, bu da ev arkaplanı artık `ResizeImage` olduğu için bir tip hatasına (ve garip bir
`flutter_test` iç matcher assertion'ına) yol açıyordu. Test, `widget.image is AssetImage` guard'ı
eklenerek düzeltildi — davranış kusuru testte, üretim kodunda değildi. `flutter analyze` temiz,
170/170 test geçiyor.

### Araştırılan ama DEĞİŞTİRİLMEYEN bulgular (risk/fayda dengesi nedeniyle ertelendi)

| # | Bulgu | Neden ertelendi |
|---|---|---|
| P5 | **[HIGH]** `GameScreen`'in ana `BoardGrid`'i (`enableParticles` varsayılan `true`) bir `Newton` parçacık sistemini TÜM round boyunca (dakikalarca) mount ediyor; `newton_particles` paketinin kendi `Ticker`'ı boşta bile her frame'de planlanıyor (`0.3.0`→`0.4.1` changelog'u doğrulandı: idle-ticker/frame-scheduling ile ilgili HİÇBİR düzeltme yok, paket yükseltmesi bunu çözmüyor). Tutorial ekranı zaten bunun için `enableParticles: false` kullanıyor (CLAUDE.md'de belgeli), ama asıl oyun ekranı — çok daha uzun süre çalışan asıl ekran — bunu hiç kullanmıyor. | Oyun içi toz patlaması/kıvılcım/konfeti efektleri gerçek oynanış sırasında aktif olarak kullanılıyor (parça yerleştirme, sıra temizleme, çerçeve yıkımı) — tutorial'daki gibi bütünüyle kapatmak mümkün değil. Gerçek düzeltme, paketin kendi `Ticker`'ını dıştan durdurup effect eklenince yeniden başlatan bir fork/patch veya özel bir on-demand parçacık sistemi gerektirir — bu, mevcut geniş kapsamlı denetim turunun güvenli/düşük riskli değişiklik sınırının dışında. **Ayrı, odaklı bir görev olarak önerilir.** |
| P6 | **[MEDIUM]** `GameScreen` hem tüm `GameSession`'ı hem tüm `PlayerProgress`'i tek `build()`'te izliyor — booster şarjı gibi tek-alanlık bir değişiklik bile `BoardGrid`/`PieceTray`/`BoosterBar`/footer'ı içeren koca alt ağacı yeniden inşa ediyor (per-cell `RepaintBoundary` sayesinde gerçek *paint* maliyeti düşük kalıyor, ama Dart-taraflı widget kurulumu israf). | `GameSession`/`PlayerProgress` tek bir immutable blob olduğu için gerçek bir düzeltme (`select` ile alt-widget'lara göre daraltma) `GameScreen`'in ve çocuklarının imza/parametre yapısını genişçe değiştirmeyi gerektirir — riskli, geniş kapsamlı bir refactor. **Ayrı bir turda, kapsamı netleştirilerek yapılmalı.** |
| P7 | **[MEDIUM]** `BoardGrid._onDragMove`, sürüklenen parça geçerli bir hücreye her girişinde tam bir board kopyası (`List.from`, 100 eleman) + `findCompletedLines` taraması (200 hücre okuma + 20 `List<GridPosition>` alokasyonu) yapıyor — yalnızca "bu satır/sütun tamamlanacak" önizleme rengini hesaplamak için. | Zaten "yalnızca hücre değiştiğinde" korumasıyla sınırlı (her pointer-move'da değil); asıl sürükle-bırak/yerleştirme mantığının kalbine dokunan bir optimizasyon, dikkatli/izole bir turda ele alınmalı. |
| P8 | **[LOW]** `splash_screen.dart`'taki `eyegames_logo.png` de aynı `cacheWidth`/`cacheHeight` optimizasyonunu alabilirdi. | Görsel şu an `const Image(...)` olarak tanımlı (kendi build-performans avantajı) — `MediaQuery` eklemek bunu non-const yapardı; görsel yalnızca soğuk açılışta 3 saniye gösteriliyor, kazanç ihmal edilebilir düzeyde, const'luğu feda etmeye değmedi. |

---

## BÖLÜM D — Aşama 4: Game Security

`Explore` ajanıyla 9 kategoride tarama yapıldı: yerel save-verisi kurcalama direnci, Supabase anon
key'in mobil taraftan istismar yüzeyi, üçüncü parti SDK secret'ları, kod obfuscation, root/jailbreak
tespiti, debug/test kodu sızıntısı, ağ güvenliği (HTTPS/pinning), izinler, App Tracking Transparency.

### Düzeltilen bulgular

| # | Bulgu | Konum | Durum |
|---|---|---|---|
| G1 | **[CRITICAL]** `app_tracking_transparency` paketi pubspec'te vardı ve `Info.plist`'te `NSUserTrackingUsageDescription` string'i hazırdı, ama gerçek kod hiçbir yerde ATT iznini istemiyordu — `AdMobAdsService.init()` iOS'ta `MobileAds.instance.initialize()`'ı ATT onayı beklemeden çağırıyordu. Yarım bırakılmış bir entegrasyon; App Store'un IDFA-tracking-capable SDK'ları ATT promptından önce initialize etmeyi reddetme kuralına gerçek bir ihlal riski. | `lib/core/services/ads/admob_ads_service.dart` | ✅ `init()` artık iOS'ta önce `AppTrackingTransparency.trackingAuthorizationStatus`'u kontrol edip `notDetermined` ise `requestTrackingAuthorization()`'ı bekliyor, ancak ondan sonra `MobileAds.instance.initialize()` çağrılıyor. Android'de dokunulmadı (paket iOS-only). **Not**: `adsServiceProvider` şu an hiçbir yerde `watch`/`read` edilmiyor (Ödüllü Reklam artık in-house ekranı kullanıyor, CLAUDE.md'de belgeli) — yani bu kod yolu bugün prod'da hiç çalışmıyor, ama gelecekte tekrar bağlanırsa (CLAUDE.md'nin öngördüğü gibi) artık doğru davranacak. `flutter analyze` temiz, 170/170 test geçti. |

### Araştırılan ama gerçek bir sorun OLMADIĞI için bulgu sayılmayan maddeler

- **Yerel save verisi düz metin/kurcalanabilir** — evet, ama tek oyunculu, sunucu-otoriter olmayan,
  liderlik tablosu/PvP'si olmayan bir oyunda kendi kendini kandırma dışında bir etkisi yok; checksum/
  şifreleme eklemek gerçek IAP bağlanana kadar gereksiz mühendislik. **Bilinçli olarak dokunulmadı.**
- **Root/jailbreak tespiti yok** — doğru durum; bunu gerektirecek bir DRM/anti-cheat/gerçek-para IAP
  yüzeyi şu an aktif değil (`purchases_flutter` zaten kullanılmıyor, bkz. A7).
- **TLS pinning yok** — Supabase bağlantısında finansal/PII veri yok (yalnızca anonim `ad_views`
  insert'i), Android/iOS ikisi de varsayılan olarak HTTPS-only zaten zorunlu. Pinning eklemek
  sertifika rotasyonu riskiyle orantısız fayda getirirdi. **Gerekli değil.**
- **İzinler** — Android release manifestinde SIFIR dangerous permission, iOS'ta yalnızca ATT string'i
  var. Zaten minimal/doğru — bulgu değil, pozitif doğrulama.
- **Debug/test kodu** — `print`/`debugPrint`/`assert`/`kDebugMode` sıfır kullanım; loglama zaten
  `package:logger`'ın release'de otomatik susturulan `DevelopmentFilter`'ı üzerinden. Temiz.

### Ertelenen bulgu (kapsamı başka bir aşamaya ait)

| # | Bulgu | Neden ertelendi |
|---|---|---|
| G2 | **[LOW-MEDIUM]** `ad_views` tablosuna anon `INSERT` politikası (`with check (true)`) rate-limit'siz — APK'dan çıkarılan anon key ile Supabase REST endpoint'ine doğrudan sahte satır spam'i mümkün (yalnızca eyegames.net'in analytics panelini kirletir, PII/para riski yok). | Bu, Aşama 1'de zaten B2 olarak eyegames.net tarafında bulunmuştu; mobil taraf yalnızca aynı anon key'i kullanıyor, ayrı bir mobil-özel açık değil. Düzeltmesi (rate-limit/App Check) eyegames.net/Supabase tarafında, **Aşama 6 (Web Security)** kapsamında ele alınacak. |
| G3 | **[MEDIUM]** Release build'de `--obfuscate --split-debug-info` kullanılmıyor (`flutter build apk --release`, düz). R8/ProGuard eksikliğiyle (A3) aynı köke sahip — ikisi de "release build sertleştirme" kapsamında. | **Aşama 5 (Flutter Release Hazırlığı)**'nda A3 ile birlikte ele alınacak — ikisi de aynı release-build-komutu değişikliğinin parçası, ayrı ayrı yapmak anlamsız tekrar olurdu. |

---

## BÖLÜM E — Aşama 5: Flutter Release Hazırlığı

### Düzeltilen bulgular

| # | Bulgu | Konum | Durum |
|---|---|---|---|
| A2 | iOS Privacy Manifest (`PrivacyInfo.xcprivacy`) tamamen eksikti. | `ios/Runner/` | ✅ Oluşturuldu (`NSPrivacyTracking: true` — AdMob+ATT gerçek tracking yaptığı için, `NSPrivacyCollectedDataTypes` → Device ID/advertising, `NSPrivacyAccessedAPITypes` → UserDefaults [`shared_preferences`] + FileTimestamp [prosedürel SFX'in geçici WAV yazma davranışı] gerekçe kodlarıyla). Xcode projesine (`project.pbxproj`) PBXBuildFile/PBXFileReference/PBXGroup/PBXResourcesBuildPhase girdileri eklenerek Runner target'ının "Copy Bundle Resources" adımına dahil edildi — yalnızca diskte durmuyor, gerçekten build'e giriyor. **Doğrulama sınırı**: bu makinede Xcode yok, XML well-formedness (PowerShell `[xml]` parser) ve pbxproj brace/paren dengesi (script ile) doğrulandı, ama gerçek bir `xcodebuild archive` + Xcode'un "Generate Privacy Report" aracıyla (yalnızca Mac'te mümkün) üçüncü parti SDK'ların (AdMob vb.) kendi bundle ettiği manifestlerle birlikte TAM uyumluluk kullanıcı tarafından mağaza gönderiminden önce teyit edilmeli. |
| A3 | Android release build'de R8/ProGuard/minify/shrinkResources hiç yapılandırılmamıştı. | `android/app/build.gradle.kts` | ✅ `isMinifyEnabled = true`, `isShrinkResources = true`, `proguardFiles(getDefaultProguardFile(...), "proguard-rules.pro")` eklendi. Yeni `android/app/proguard-rules.pro`: Flutter'ın kendi embedding/plugin-loader keep kuralları + AdMob için savunmacı bir keep + Play Core split-install sınıfları için `-dontwarn` (bu proje Play Feature Delivery kullanmıyor, bu sınıflar GERÇEKTEN classpath'te yok — Flutter+AGP8'in bilinen bir etkileşimi, uygulamaya özgü değil). |
| G3 | Release build Dart-taraflı obfuscation (`--obfuscate --split-debug-info`) kullanmıyordu. | build komutu (gradle dosyası değil) | ✅ `flutter build apk --release --obfuscate --split-debug-info=build/symbols` ile GERÇEK bir release build alınıp doğrulandı (aşağıya bkz.) — bu bayrakların Codemagic'e (Aşama 12) kalıcı olarak gömülmesi gerekiyor, tek seferlik manuel komutun kendisi kalıcı bir çözüm değil. |

**Gerçek build + smoke-test doğrulaması (bu turda yapıldı)**: `flutter build apk --release --obfuscate --split-debug-info=build/symbols` ilk denemede R8 "Missing classes" hatasıyla BAŞARISIZ oldu (`com.google.android.play.core.splitinstall.*` — Flutter'ın Play Feature Delivery için opsiyonel bir bağımlılığı, bu proje kullanmadığı için classpath'te yok) — `proguard-rules.pro`'ya `-dontwarn com.google.android.play.core.**` eklenip DÜZELTİLDİ, ikinci denemede **64.0MB APK başarıyla üretildi**, `build/symbols/*.symbols` (3 mimari) ve `build/app/outputs/mapping/release/mapping.txt` (R8 mapping, gelecekteki crash sembolikasyonu için) oluştu. Emülatöre kurulup (`pm install`) gerçekten çalıştırıldı: ana menü, Level Mod'a giriş, tahta/booster/tepsi/footer'ın TAMAMI doğru render oldu (ekran görüntüsüyle doğrulandı), `adb logcat`'te SIFIR `FATAL`/`AndroidRuntime`/exception — yani minify+obfuscate GERÇEK bir R8-kaynaklı reflection kırılması (Riverpod codegen, Freezed, json_serializable gibi kod-üretimli katmanlarda sık görülen bir risk sınıfı) YARATMADI. `flutter analyze` temiz, 170/170 test geçti (test suite zaten debug/JIT modunda çalışıyor, release-obfuscation'dan etkilenmez — asıl kanıt gerçek cihaz/emülatör smoke-testiydi).

### Araştırılan ama YANLIŞ POZİTİF çıkan bulgular (düzeltilmedi)

| # | Bulgu | Neden yanlış pozitif |
|---|---|---|
| A5 | minSdk/targetSdk/compileSdk `flutter.*` üzerinden geliyor, açıkça sabitlenmemiş. | A8'le (`intl: any`) AYNI kalıp: `flutter.compileSdkVersion` vb. kullanmak Flutter'ın KENDİ güncel şablon konvansiyonu — Android SDK seviyelerini elle sabitlemek, kurulu Flutter SDK sürümünün gerektirdiği native kütüphane/plugin uyumluluğundan geride kalma riski taşır. GERÇEK reproducibility, Android SDK seviyesini değil **Flutter SDK sürümünün kendisini** pinlemekten gelir — bu, Aşama 12'nin (Codemagic) açıkça istediği "Flutter Version Pinning" maddesiyle zaten karşılanacak. Koda dokunulmadı. |
| A12 | iOS `UIBackgroundModes` yok. | Uygulamanın ses sistemi bilinçli olarak `AVAudioSessionCategory.ambient` kullanıyor (CLAUDE.md'de belgeli — ekran kilitlenince/arka plana geçince SES KESİLSİN diye, tam da bir bulmaca oyununun istediği davranış). `UIBackgroundModes`'un `audio` girişi TAM OLARAK bunun tersini (arka planda sesin DEVAM etmesini) sağlar — yani bu anahtarın YOKLUĞU bir eksiklik değil, mevcut tasarımla TUTARLI doğru durum. Dokunulmadı. |

### Kullanıcı aksiyonu gereken maddeler (ben üretemem/tahmin edemem)

| # | Bulgu | Neden bekliyor |
|---|---|---|
| A1 | AdMob App ID + ad-unit ID'leri hâlâ Google'ın herkese açık TEST değerleri. | Gerçek ID'ler AdMob console'undan (kullanıcının kendi hesabı) alınmalı — ben üretemem. `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` (`GADApplicationIdentifier`), `lib/core/services/ads/admob_ads_service.dart:18-21`. |
| — | `applicationId`/`namespace` hâlâ `com.bbblock.bb_block` (placeholder). | Gerçek ters-domain (ör. `net.eyegames.bbblock`) kullanıcının kararı — CLAUDE.md'de zaten bilinen açık nokta. |
| A13 | iOS hem portrait hem landscape açık. | Tasarım kararı (10x10 tahta oyunu için portrait-only kilit mantıklı olabilir ama bu bir ÜRÜN kararı, teknik zorunluluk değil) — Aşama 8 (UI Review) veya kullanıcı onayı bekliyor, kod DEĞİŞTİRİLMEDİ. |

---

## BÖLÜM F — Aşama 6: Web Security (eyegames.net)

`Explore` ajanıyla 9 kategoride taze bir tarama yapıldı: CSRF, CORS, rate-limiting, session güvenliği,
input validation/injection, bağımlılık zafiyetleri (`npm audit`), hata mesajı sızıntısı, open redirect,
clickjacking. **Genel sonuç: site beklenenden çok daha sağlam** — CSRF/CORS/open-redirect/clickjacking
kategorilerinde SIFIR bulgu, `npm audit` temiz (0 zafiyet), session/auth zaten iki katmanlı ve doğru.

### Düzeltilen bulgular

| # | Bulgu | Konum | Durum |
|---|---|---|---|
| W1 | **[LOW]** Cron endpoint, Supabase upsert hatasında ham Postgres/Supabase hata mesajını (`error.message`) doğrudan istemciye dönüyordu (tablo/kolon adları sızabilir). Gerçek risk düşük (yalnızca `CRON_SECRET`'ı bilen biri bu koda ulaşabiliyor), ama savunma-derinliği eksikti. | `app/api/cron/sync-store-stats/route.ts` | ✅ Hata artık sunucu tarafında (`console.error`, Vercel function log'larına düşüyor) loglanıyor, istemciye jenerik `"internal error"` dönüyor. `tsc`/`eslint` temiz. |
| W2 | **[LOW, dokümantasyon]** `docs/TASKS.md`'de "Contact form: Zod validation + honeypot + origin kontrolü + IP bazlı rate limit" TAMAMLANDI ("[x]") olarak işaretliydi, ama gerçek kod (`components/sections/contact.tsx`) düz bir `mailto:` linki — form, validation, rate-limit hiç var olmadı. İstismar edilebilir değil (sahte bir güvenlik önlemi VAR SANMAK'tan daha kötüsü yok — kod yolu hiç yok, saldırı yüzeyi de yok), ama gelecekte yanıltıcı olurdu. | `docs/TASKS.md` | ✅ İki madde de gerçek duruma göre düzeltildi. |

### Araştırılıp bilinçli olarak dokunulmayan bulgu

| # | Bulgu | Karar |
|---|---|---|
| G2/B2 | `ad_views` tablosuna anon `INSERT` rate-limit'siz — APK'dan çıkarılan anon key ile sahte satır spam'i mümkün. | **Bilinçli olarak dokunulmadı — "hiçbir şey yapmamak" burada savunulabilir bir karar.** Üç mitigasyon seçeneği değerlendirildi: (1) Supabase'in platform-seviyesi rate-limit'i bu senaryoyu (anon key'e özel per-tablo throttle) KAPSAMIYOR, uygulanabilir değil. (2) Mobil uygulamanın gönderdiği özel bir header/User-Agent kontrolü — SAHTE güvenlik, header aynı APK'nın içinde, anon key ile AYNI kolaylıkla çıkarılır. (3) Postgres tarafında IP-bazlı gerçek bir trigger/rate-limit — TEK gerçek mitigasyon, ama şema karmaşıklığı + her insert'te ekstra sorgu maliyeti getiriyor. Etki tavanı yalnızca "iç analytics panelini kirletme" (PII/finansal veri/RLS-okuma riski YOK, `anon` hâlâ yalnızca INSERT yapabiliyor) — maliyet/fayda dengesi (3)'ü şu an gerektirmiyor. İleride gerçek bir iş kararına dayanacaksa (ör. panel gerçek gelir raporlamasına bağlanırsa) yeniden değerlendirilebilir. |

### Zaten doğru/temiz bulunan (yeni bulgu değil, doğrulama)

CSRF (mutasyon yapan hiçbir Server Action/cookie-authenticated route yok, cron GET+bearer-token
kullanıyor, CSRF'in hedefi olamaz), CORS (hiç yapılandırılmamış, ama zaten gerekmiyor), session
güvenliği (`@supabase/ssr` varsayılanları — HttpOnly/Secure/SameSite=Lax — hiç override edilmemiş, hem
`proxy.ts` hem `layout.tsx` gerçek `getUser()` ile fail-closed), injection/XSS (tüm Supabase sorguları
parametreli, tek `dangerouslySetInnerHTML` yalnızca statik geliştirici-verisi render ediyor), bağımlılık
zafiyetleri (`npm audit` — 0 zafiyet, kilitli lockfile commit'li), open redirect (SIFIR — tüm
`redirect()`/`router.push()` hedefleri hardcoded literal), clickjacking (`frame-ancestors 'none'` +
`X-Frame-Options: DENY` tüm route'larda, `/admin` dahil, kapsam daralması yok).

---

## BÖLÜM G — Aşama 7: SEO + GEO (eyegames.net)

`Explore` ajanıyla 9 kategoride tarama yapıldı: metadata eksiksizliği, JSON-LD doğruluğu, sitemap
(B3), robots.txt, canonical URL'ler, başlık hiyerarşisi, görsel alt-text, GEO (LLM-taraflı
keşfedilebilirlik), performans-bitişik SEO sinyalleri. **Genel sonuç: legal sayfalar/canonical/alt-
text/font zaten iyi durumdaydı, ama gerçek ve daha önce hiç yakalanmamış bir bulgu ortaya çıktı: admin
paneli arama motorlarına tamamen açıktı.**

### Düzeltilen bulgular

| # | Bulgu | Konum | Durum |
|---|---|---|---|
| S1 | **[HIGH, yeni bulgu]** `/admin` ve `/admin/login` hiçbir `robots`/`noindex` direktifi taşımıyordu VE `robots.ts` `/admin`'i disallow etmiyordu — kök layout'un varsayılan `index:true, follow:true`'unu miras alıyorlardı. Kimliksiz bir crawler `/admin`'e gidip `/admin/login`'e (gerçek 200 durumlu, indexlenebilir bir giriş formu) yönlendiriliyor. Arama sonuçlarında bir admin giriş ekranının belirmesi riski (Phase 1'de hiç yakalanmamıştı). | `app/robots.ts`, yeni `app/admin/layout.tsx` | ✅ `robots.ts`'e `disallow: "/admin"` eklendi; yeni `app/admin/layout.tsx` (Server Component, `/admin/login`'i de `(protected)` grubunu da sarıyor) `robots: {index:false, follow:false}` metadata'sı export ediyor — `/admin/login` bir Client Component olduğu için `metadata` export edemiyordu, bu yüzden paylaşılan bir üst layout gerekti. **Gerçek `next build` + `next start` ile uçtan uca doğrulandı**: `curl /admin/login` çıktısında `<meta name="robots" content="noindex, nofollow"/>` gerçekten render oluyor, `curl /robots.txt` `Disallow: /admin` içeriyor. |
| B3 | Sitemap yalnızca ana sayfayı listeliyordu, 3 yasal sayfa eksikti. | `app/sitemap.ts` | ✅ 3 sayfa eklendi (`lastModified` sayfaların kendi görünen "4 Ağustos 2026" tarihiyle eşleşiyor, `changeFrequency: yearly`, `priority: 0.3` — ana sayfanın `weekly`/`1`'inden bilinçli olarak düşük). **Gerçek `curl /sitemap.xml` çıktısıyla doğrulandı** — 4 URL de doğru göründü. |
| S2 | **[LOW]** `games.tsx`/`faq.tsx`/`contact.tsx`'in `<section aria-labelledby="...">`si var olmayan bir DOM ID'sine işaret ediyordu — `SectionHeading`'in `<h2>`'si hiç `id` almıyordu (yalnızca `studio.tsx`, `SectionHeading` kullanmadığı için kendi elle yazdığı `<h2 id="studio-heading">` ile doğruydu). | `components/ui/section-heading.tsx` + 3 çağıran dosya | ✅ `SectionHeading`'e opsiyonel `headingId` prop'u eklendi, `<h2 id={headingId}>`, üç çağrı yerine (`games-heading`/`faq-heading`/`contact-heading`) geçirildi. |

**Doğrulama**: `npx tsc --noEmit` + `npx eslint .` temiz, **gerçek bir `next build` (production,
Turbopack) başarıyla tamamlandı** (tüm route'lar — `/admin`, `/admin/login`, `/sitemap.xml`,
`/robots.txt` dahil — derlendi), ardından `next start` ile GERÇEKTEN çalıştırılıp `curl` ile üç
değişikliğin de (sitemap içeriği, robots.txt disallow, admin noindex meta tag) canlı çıktısı
doğrulandı — yalnızca statik kod okuması değil, çalışan bir sunucudan gerçek HTTP yanıtı.

### Araştırılıp, ürün/içerik kararı olduğu için KOD DEĞİŞİKLİĞİ yapılmadan flaglenen maddeler

| # | Bulgu | Neden ertelendi |
|---|---|---|
| S3 | FAQ akordeonunun 4/5 cevabı ilk yüklemede DOM'da yok (yalnızca açık olan görünüyor) — JSON-LD'de tüm 5 cevap var, ama düz-metin/GEO çıkarımı yapan bir pipeline yalnızca 1'ini görür. | UI/UX davranış değişikliği (akordeonun görsel/etkileşim mantığına dokunur) — bu denetimin "gameplay/UI davranışına dokunma" kısıtı web tarafı için de temkinli uygulandı, Aşama 8 (UI Review) önerisi olarak bırakıldı. |
| S4 | Kurucu isimleri (Emir Kayar, Yunus Emre Başkan) yalnızca JSON-LD'de var, görünür sayfa metninde hiç geçmiyor — GEO açısından kayıp (LLM'ler genelde JSON-LD'yi değil görünür metni çıkarır). | İçerik/tasarım kararı (yeni bir "Ekibimiz" bölümü eklemek gerekir) — kod bug'ı değil, öneri olarak bırakıldı. |
| S5 | `Organization.sameAs` sabit boş dizi — sosyal linkler canlı olduğunda otomatik dolmuyor. | Sosyal linkler zaten şu an `href: null` (henüz yayında değil) — şu an yapılacak bir şey yok, sosyal hesaplar açıldığında hem `site-config.ts` hem `json-ld.ts` birlikte güncellenmeli. |
| S6 | "Şimdi Oynanabilir" rozeti + `status: "live"` gösteriliyor ama gerçek bir indirme/mağaza linki yok (oyun henüz App Store'da yayınlanmadı). | Teknik bir SEO hatası değil, iş/ürün kararı — mağaza linki eklenince otomatik çözülür. |
| S7 | `VideoGame` JSON-LD'sinde `image`/`applicationCategory`/`operatingSystem` eksik. | Gerçek bir mağaza linki/görsel olmadan eklemek anlamsız — mağaza yayınlandığında birlikte eklenmeli. |

### Zaten doğru/temiz bulunan (yeni bulgu değil, doğrulama)

Legal sayfaların (gizlilik/kullanım şartları/çerez) her biri kendi benzersiz title/description/
canonical'ına sahip — "tekrarlayan canonical" şüphesi DOĞRULANMADI, zaten doğru. `next/font` self-
hosting, tüm görsellerde `next/image` + anlamlı `alt` metni, başlık hiyerarşisi (tek `h1`/sayfa,
mantıklı h2→h3 nesting), JSON-LD içeriğinin sayfa metniyle senkron olması (stale veri yok) — hepsi
doğrulandı, bulgu yok.

---

## BÖLÜM H — Aşama 8: UI Review (yalnızca ÖNERİ — hiçbir madde uygulanmadı)

**Kritik kural (kullanıcı talimatı):** Bu bölüm SADECE öneri raporudur. Aşağıdaki hiçbir madde
kullanıcı onayı olmadan uygulanmayacak. `Explore` ajanıyla iki proje için de "zaten neyin iyi olduğunu
tekrar keşfetme, gerçek boşlukları bul" talimatıyla tarama yapıldı — ikisi de zaten olgun bir animasyon
diline sahip (BB Block'un "Game Feel Engine"i, eyegames.net'in GSAP-scroll-cinematic dili), bu yüzden
rapor yalnızca GERÇEK boşluklara odaklanıyor, dolgu madde yok.

### BB Block (Flutter) — öneriler

| # | Öncelik | Bulgu | Efor | Mevcut dille tutarlı mı? |
|---|---|---|---|---|
| U1 | Yüksek | Pause/Round-Over overlay'leri hiçbir giriş animasyonu olmadan aniden beliriyor (`game_screen.dart` `_PauseOverlay`/`_RoundOverlay`) — bir katman içeride confetti/score-count-up gibi zengin animasyon varken, overlay'in kendisi sert bir `if` swap. | Küçük | Evet — mevcut sistemdeki bir boşluğu dolduruyor |
| U2 | Yüksek | İkincil kontroller (Ayarlar'daki ses/dil/kredi satırları, TextButton'lar, stock `Switch`) `SpringPressable`+haptik+ses katmanlamasını almıyor — birincil CTA'ların yanında "cansız" duruyorlar. | Küçük-Orta | Evet |
| U3 | Yüksek | Ödüllü reklam ekranındaki 5 yıldızlı puanlama satırı dokunuşta hiç tepki vermiyor (stock `IconButton`, anlık swap). | Küçük | Evet |
| U4 | Orta | Tutorial adım geçişleri (`_advanceAfterDelay`) sert bir `setState` kesmesi — rehber el animasyonu özenli ama adım geçişinin kendisi değil. | Küçük | Evet |
| U5 | Orta | Home→Game/Settings/Tutorial arası go_router geçişleri stok platform animasyonu kullanıyor, özel `CustomTransitionPage` yok. | Orta | Yeni ama düşük riskli |
| U6 | Düşük | Devre dışı durum opaklık değişimleri (`Opacity`) anında kesiliyor, `AnimatedOpacity` değil. | Çok küçük | Evet |
| U7 | Düşük | Tutorial bitiş anı yalnızca düz bir 400ms bekleme, görsel bir "ödül" anı yok (kod kendi yorumunda zaten bunu "yarım bırakılmış" olarak işaretliyor). | Küçük | Evet |

### eyegames.net — öneriler

| # | Öncelik | Bulgu | Efor | Mevcut dille tutarlı mı? |
|---|---|---|---|---|
| U8 | Yüksek | Admin paneli: `app/admin/(protected)/page.tsx` bloklayıcı bir server-side fetch yapıyor ama hiçbir loading skeleton yok; `/admin/login`'in input'larında `transition-colors` eksik (dosyanın geri kalanında ve sitenin her yerinde var) — GSAP eklemek gerekmiyor, yalnızca eksik bir temel tutarlılık. | Küçük | Mevcut taban çizgisiyle tutarsızlığı düzeltiyor |
| U9 | Yüksek | `app/error.tsx`/`app/not-found.tsx` düz statik metin — `Reveal` bileşeni zaten var ve kolayca kullanılabilir, ama bu iki sayfada hiç kullanılmamış. (`global-error.tsx` BİLEREK dokunulmamalı — root layout çökerse client motion kütüphanelerine güvenemez.) | Küçük | Evet, mevcut `Reveal` bileşenini tekrar kullanıyor |
| U10 | Orta | Yasal sayfalar (`legal-page.tsx`) hiç `Reveal` almıyor — ana sayfanın HER bölümü `Reveal`/`RevealGroup` kullanırken, yasal sayfalar aynı site içinde "farklı/eski bir site" hissi veriyor. | Küçük | Evet, en yüksek tutarlılık/risk oranı |
| U11 | Orta (opsiyonel) | Ana sayfa↔yasal sayfalar arası route geçişi yok. `/admin`'e KASITLI olarak dokunulmamalı (zaten bilinçli olarak sade tutulmuş, `app/layout.tsx` yorumu bunu doğruluyor). | Orta | Yeni, dikkatli yapılmalı (Lenis/SmoothScroll re-init riski) |

**Bilinçli olarak ÖNERİLMEYEN maddeler** (dürüstçe not edildi): admin panelinde sayı count-up
animasyonu, grafik çizgisinin çizilerek belirmesi, kart hover-tilt — iç kullanım amaçlı, çok az kişi
görüyor, efor/fayda oranı düşük. eyegames.net'in geri kalanı (hero parallax, magnetic button, tilt
card, custom cursor, easter egg'ler, scroll progress, `prefers-reduced-motion` fallback) zaten iyi
kapsanmış, ek iş önerilmiyor.

---

## BÖLÜM I — Aşama 9: Project Structure (Mimari Değerlendirme)

Bu aşama BB Block'ta zaten CLAUDE.md'nin kapsamlı şekilde belgelediği mimariyi yeniden keşfetmek yerine
somut, script-doğrulanabilir iddiaları GERÇEKTEN test etti (grep ile), varsayım olarak bırakmadı.

### BB Block (Flutter) — Clean Architecture doğrulaması

- **İddia**: "Engine katmanları (`board/scoring/piece_generation/booster/game_engine`'in `domain/`
  klasörleri) `flutter/*` import etmez." → `grep -rl "package:flutter/" lib/features/*/domain/` ile
  gerçekten test edildi: **SIFIR eşleşme.** Domain katmanı gerçekten saf.
- **İddia**: "application katmanı presentation'a bağımlı değil" → `grep -rl "presentation/"
  lib/features/*/application/`: **SIFIR eşleşme.** Katman yönü doğru (yukarıdan aşağıya, tersi yok).
- **Dosya boyutu taraması**: `game_screen.dart` (1143 satır) ve `board_grid.dart` (1063 satır) kod
  tabanının en büyük iki dosyası — çok sayıda private widget sınıfı (`_RoundOverlay`, `_PauseOverlay`,
  `_Header`, `_Footer` vb.) tek dosyada birikmiş. **Bu bir SOLID/mimari İHLALİ değil** (bu private
  sınıflar başka hiçbir yerde kullanılmıyor, Flutter'da "ekranına özel private widget'ları aynı dosyada
  tutmak" yaygın ve makul bir stil tercihi), ama **[LOW, izlenmeye değer]**: dosyalar büyümeye devam
  ederse (özellikle `game_screen.dart`) okunabilirlik için `widgets/` alt klasörüne bölünmesi
  düşünülebilir. Şu an acil değil, yalnızca not edildi.
- **Feature-first klasör yapısı**: `domain/application/presentation/data` ayrımı tüm feature'larda
  tutarlı — CLAUDE.md'nin iddia ettiği gibi.

### eyegames.net (Next.js) — mimari değerlendirmesi

- **Dosya boyutları**: en büyük dosya 187 satır (`hero.tsx`) — genel olarak küçük, odaklı dosyalar,
  hiçbir "god component" yok.
- **Kritik güvenlik-bitişik mimari kontrolü**: `lib/supabase/admin.ts` (service-role client, RLS'i
  bypass eder) hiçbir `"use client"` bileşeni tarafından import edilmiyor mu? → `grep` ile gerçekten
  test edildi: **SIFIR eşleşme** — service-role client yalnızca sunucu tarafı kodda (route handler,
  Server Component) kullanılıyor, client bundle'ına hiç sızmıyor. Bu, "yanlışlıkla service-role key'i
  tarayıcıya gönderme" sınıfındaki en yaygın Next.js/Supabase hatasının burada YAŞANMADIĞININ somut
  kanıtı.
- Route group ayrımı (`(marketing)` vs `admin/`) net — CLAUDE.md/Phase 8'in de doğruladığı gibi admin
  bilinçli olarak marketing chrome'undan (Navbar/Footer/Cursor/SmoothScroll) ayrı tutulmuş.

### Sonuç

**İki projede de gerçek bir mimari ihlal bulunamadı.** Bu aşamanın kendine özgü katkısı, önceki
oturumların/CLAUDE.md'nin iddialarını körü körüne kabul etmek yerine somut olarak DOĞRULAMAK oldu.

## Sonraki Adım

**Aşama 1 ve Aşama 2 tamamlandı (2026-08-05).** Aşama 2 sonuçları:
- A4 (freezed stabil sürüme geçiş): düzeltildi, test-doğrulandı.
- A6 (test_ad.png yeniden adlandırma): düzeltildi.
- B1 (cron endpoint fail-closed): kod tarafı düzeltildi; Vercel Production'da `CRON_SECRET` set etmek
  hâlâ kullanıcı aksiyonu gerektiriyor (bu asistanın Vercel erişimi yok).
- A8 ve A9: araştırma sonucu **yanlış pozitif** çıktı, düzeltme yapılmadı, rapor buna göre güncellendi —
  ikisi de aslında doğru/kasıtlı mevcut durum.
- A7 (purchases_flutter): kullanıcı karar veremedi, dokunulmadan bırakıldı.

**Aşama 3 tamamlandı (2026-08-05).** 4 bulgu düzeltildi ve test-doğrulandı (P1-P4), 4 bulgu
araştırıldı ama risk/kapsam nedeniyle bilinçli olarak ertelendi (P5-P8, hepsi Bölüm C'de detaylı).
En önemli erteleme: P5 (`GameScreen`'in ana `Newton` parçacık sistemi sürekli çalışıyor) — gerçek bir
bulgu, ama güvenli düzeltmesi ayrı/odaklı bir görev gerektiriyor.

**Aşama 4 tamamlandı (2026-08-05).** 1 CRITICAL bulgu düzeltildi ve test-doğrulandı (G1 — App Tracking
Transparency hiç bağlanmamıştı, gerçek bir App Store red riskiydi). Geri kalan 5 araştırılan madde
(yerel save kurcalama, root tespiti, TLS pinning, izinler, debug kod sızıntısı) bu oyun sınıfı için
gerçek bir sorun olmadığı gerekçesiyle bilinçli olarak dokunulmadı; 2 madde (G2/G3) kapsamları
gereği Aşama 5/6'ya ertelendi.

**Aşama 5 tamamlandı (2026-08-05).** A2 (iOS Privacy Manifest) + A3/G3 (R8/ProGuard/minify/
obfuscate) düzeltildi ve GERÇEK bir release build + emülatör smoke-testiyle doğrulandı (64.0MB APK,
sıfır crash). A5/A12 araştırılınca yanlış pozitif çıktı. A1 (gerçek AdMob ID'leri) ve applicationId
placeholder'ı kullanıcı aksiyonu gerektiriyor — ben gerçek değerler üretemem. A13 (iOS orientation)
bir ürün kararı, dokunulmadı.

**Aşama 6 tamamlandı (2026-08-05).** eyegames.net beklenenden çok daha sağlam çıktı — CSRF/CORS/open-
redirect/clickjacking'de sıfır bulgu, `npm audit` temiz. 2 LOW bulgu düzeltildi (W1: hata mesajı
sızıntısı, W2: yanıltıcı doküman). G2/B2 (rate-limit) bilinçli olarak "hiçbir şey yapma" kararıyla
kapatıldı — gerekçe raporda.

**Aşama 7 tamamlandı (2026-08-05).** B3 (sitemap) düzeltildi. Daha önemlisi: yeni, daha önce hiç
yakalanmamış bir HIGH bulgu bulundu ve düzeltildi (S1 — admin paneli arama motorlarına tamamen açıktı).
1 LOW bulgu (S2 — aria-labelledby/id uyumsuzluğu) düzeltildi. Tüm düzeltmeler gerçek bir `next build`
+ `next start` + `curl` ile uçtan uca doğrulandı. 4 madde (S3-S7) içerik/ürün kararı olduğu için
kod değiştirilmeden öneri olarak bırakıldı.

**Aşama 8 tamamlandı (2026-08-05) — yalnızca öneri raporu, HİÇBİR kod değişikliği yapılmadı.** 7 madde
BB Block için (U1-U7), 4 madde eyegames.net için (U8-U11) önerildi, önceliklendirildi, efor tahmini
verildi. Kullanıcının hangi maddelerin uygulanmasını istediğine karar vermesi bekleniyor.

**Aşama 9 tamamlandı (2026-08-05).** İki projede de gerçek bir mimari ihlal bulunamadı — iddialar
körü körüne kabul edilmek yerine grep ile somut doğrulandı (domain katmanı saflığı, service-role
key'in client bundle'ına sızmaması). Tek not: `game_screen.dart`/`board_grid.dart` büyüyor, izlenmeye
değer ama acil değil.

Sıradaki: **Aşama 10 — Final Report + Skor Tablosu**.
