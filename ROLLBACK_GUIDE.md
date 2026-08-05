# ROLLBACK GUIDE — BB Block + eyegames.net

**Tarih:** 2026-08-05

## eyegames.net (Vercel) — hızlı ve düşük riskli

Vercel her deploy'u ayrı bir immutable sürüm olarak tutar. Sorun çıkarsa:

1. Vercel dashboard → Deployments → önceki (çalışan) deployment'ı bul.
2. "Promote to Production" ile anında geri al — DNS/domain değişmez, saniyeler içinde etkili olur.
3. Kök nedeni bulup düzelttikten sonra tekrar deploy et.

**Bu oturumda dokunulan dosyalar geri alınması gerekirse**: `app/api/cron/sync-store-stats/route.ts`,
`app/sitemap.ts`, `app/robots.ts`, `app/admin/layout.tsx`, `components/ui/section-heading.tsx` +
3 çağıran dosya, `docs/TASKS.md`. Hepsi git history'de ayrı ayrı görünür (bu oturumda commit
yapılmadıysa, `git diff`/`git stash` ile de geri alınabilir).

## BB Block (Mobil) — YAVAŞ ve geri dönüşü sınırlı

Mobil mağazalarda "rollback" web'deki gibi anında değildir:

1. **Play Store**: Play Console'da önceki bir release'i "Halt rollout" ile durdurabilirsin (aşamalı
   yayında), ama zaten %100 yayındaysa yeni bir DÜZELTME sürümü göndermen gerekir — eski sürüme
   otomatik dönüş YOKTUR. Kullanıcılar cihazlarında yeni sürümü zaten indirmiş olabilir.
2. **App Store**: Apple'ın "Remove from sale" seçeneği var ama bu da otomatik eski sürüme dönüş
   değil, yeni gönderim gerektirir.
3. **Yerel veri geri uyumluluğu kritik**: `PlayerProgress`/`SavedRound` (shared_preferences JSON blob)
   yeni bir alan eklendiğinde ESKİ sürümün onu okuyamaması sorun yaratmaz (Freezed `@Default` ile geriye
   uyumlu), ama bir alan KALDIRILIRSA veya tipi değişirse, kullanıcı yeni sürümden eskiye geçerse
   (mağaza rollback'i olmasa da bir kullanıcı manuel eski APK yüklerse) veri bozulabilir. **Bu yüzden
   mobil tarafta "rollback" yerine "hızlı forward-fix" tercih edilmeli** — geriye dönük save
   uyumluluğunu bozmadan yeni bir düzeltme sürümü gönder.

## Genel Prensip

- **Web (eyegames.net)**: rollback = normal, hızlı, sık kullanılabilir bir araç.
- **Mobil (BB Block)**: rollback = son çare, pratikte "forward-fix" (hızlı bir düzeltme sürümü
  gönder) çoğu zaman daha güvenli ve daha hızlı gerçek dünyada etkili olur.
