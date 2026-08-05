# CHANGELOG — Production Audit Session (2026-08-05)

Bu dosya yalnızca bu denetim oturumunda (Aşama 1-9) yapılan KOD değişikliklerini listeler —
oyunun/sitenin daha geniş geliştirme geçmişi için `CLAUDE.md`'ye (BB Block) bakın.

## BB Block (`app/`)

- **A4**: `freezed` dev-prerelease (`^3.2.6-dev.1`) → gerçek stabil sürüm (`^3.2.5`) — pub.dev'de
  doğrulandı, `4.0.0-dev.3` de bir prerelease. Codegen yeniden üretildi.
- **A6**: `assets/images/test_ad.png` → `assets/images/rewarded_ad_promo.png` (kullanıcı onayıyla).
- **P1**: `lib/app.dart` — kök widget artık `PlayerProgress`'in tamamı yerine yalnızca `languageCode`'u
  `select()` ile izliyor.
- **P2**: `lib/features/game/presentation/game_screen.dart` — `_RoundOverlay` artık `Newton` parçacık
  sistemini yalnızca zafer durumunda mount ediyor.
- **P3/P4**: `rewarded_ad_screen.dart`, `home_screen.dart`, `image_background.dart` — 3 arkaplan
  görseline `cacheWidth`/`cacheHeight` eklendi.
- **G1** (CRITICAL): `lib/core/services/ads/admob_ads_service.dart` — iOS'ta App Tracking
  Transparency izni artık AdMob başlatılmadan ÖNCE isteniyor.
- **A2**: `ios/Runner/PrivacyInfo.xcprivacy` oluşturuldu, Xcode projesine (`project.pbxproj`) bağlandı.
- **A3/G3**: `android/app/build.gradle.kts` — R8/ProGuard/minify/shrinkResources etkinleştirildi, yeni
  `android/app/proguard-rules.pro` eklendi. Gerçek release build `--obfuscate --split-debug-info` ile
  doğrulandı.
- **Test düzeltmesi**: `test/core/routing/splash_screen_test.dart` — `cacheWidth`/`cacheHeight`
  eklenince `Image.asset`'in `.image`'i `ResizeImage`'a sarıldığı için testin unguarded `as AssetImage`
  cast'i kırılmıştı, `is AssetImage` guard'ıyla düzeltildi.

**Doğrulama**: `flutter analyze` (temiz) + `flutter test` (170/170) her değişiklikten sonra çalıştırıldı.
Aşama 5'te ayrıca GERÇEK bir `flutter build apk --release --obfuscate --split-debug-info` + emülatör
kurulumu + smoke-test (ekran görüntüsü + logcat) yapıldı.

## eyegames.net

- **B1** (HIGH): `app/api/cron/sync-store-stats/route.ts` — `CRON_SECRET` tanımsızken artık 500
  dönüyor (fail-closed), önceden sessizce kimliksiz çalışıyordu.
- **W1**: aynı dosya — Supabase hata mesajı artık istemciye sızmıyor, sunucu tarafında loglanıyor.
- **W2**: `docs/TASKS.md` — var olmayan bir "contact form" özelliğinin yanlışlıkla "tamamlandı"
  işaretlenmesi düzeltildi.
- **B3**: `app/sitemap.ts` — 3 yasal sayfa eklendi.
- **S1** (HIGH): `app/robots.ts` (`disallow: "/admin"`) + yeni `app/admin/layout.tsx`
  (`noindex,nofollow` metadata) — admin paneli artık arama motorlarına kapalı.
- **S2**: `components/ui/section-heading.tsx` + 3 çağıran dosya — `aria-labelledby`/`id` uyumsuzluğu
  düzeltildi.

**Doğrulama**: `npx tsc --noEmit` + `npx eslint .` her değişiklikten sonra çalıştırıldı. Ayrıca GERÇEK
bir `next build` (production, Turbopack) + `next start` + `curl` ile sitemap/robots/noindex çıktıları
canlı olarak doğrulandı.

## Yeni Dosyalar (bu oturumda oluşturuldu)

- `PROJECT_STATUS.md`, `MASTER_AUDIT_REPORT.md` — denetimin canlı ilerleme kaydı ve tam bulgu raporu.
- `PROJECT_SCORE.md`, `SECURITY_REPORT.md`, `PERFORMANCE_REPORT.md`, `KNOWN_LIMITATIONS.md`,
  `CHANGELOG.md` (bu dosya) — Aşama 10 teslimleri.
- `app/android/app/proguard-rules.pro`, `app/ios/Runner/PrivacyInfo.xcprivacy` — release-hazırlık.
