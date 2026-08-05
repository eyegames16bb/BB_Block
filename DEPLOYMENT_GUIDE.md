# DEPLOYMENT GUIDE — BB Block + eyegames.net

**Tarih:** 2026-08-05 · İki bağımsız deployment hedefi var: mobil oyun (mağaza gönderimi, manuel/
Codemagic) ve website (Vercel, otomatik).

## eyegames.net (Vercel)

Zaten otomatik: `main`'e (veya yapılandırılan production branch'e) push, Vercel otomatik build+deploy
eder. Bu denetimde dokunulan hiçbir dosya (`app/api/cron/sync-store-stats/route.ts`, `app/sitemap.ts`,
`app/robots.ts`, `app/admin/layout.tsx`, `components/sections/*.tsx`, `docs/TASKS.md`) deployment
konfigürasyonunu değiştirmedi — normal Vercel akışı geçerli.

**Deploy öncesi kontrol**: `npx tsc --noEmit` + `npx eslint .` + `npx next build` (bu denetimde hepsi
temiz/başarılı) — Vercel zaten build sırasında bunları kendisi de çalıştırır, ama push'tan önce
lokal doğrulama daha hızlı geri bildirim verir.

**Kritik ortam değişkeni eksik**: `CRON_SECRET` — Vercel Production'da set edilmemişse günlük cron
job'u artık (bu oturumdan sonra) 500 ile başarısız olur (kasıtlı, fail-closed — bkz. `SECURITY_REPORT.md`
madde B1). Deploy'dan önce bu değişkenin Vercel dashboard'unda set edildiğinden emin olunmalı.

## BB Block (Mobil — henüz manuel, Aşama 12'de Codemagic'e taşınacak)

Bkz. `RELEASE_GUIDE.md` (genel akış), `ANDROID_RELEASE.md`/`IOS_RELEASE.md` (platform detayları).
Şu an CI/CD YOK — her build/imzalama/yükleme manuel yapılıyor. Aşama 12 (kullanıcının talebiyle,
Aşama 1-11 tamamlanınca başlayacak) bunu otomatikleştirecek.

## Ortam Değişkenleri Özeti

| Proje | Değişken | Nerede | Durum |
|---|---|---|---|
| BB Block | `SUPABASE_URL`/`SUPABASE_ANON_KEY` | `--dart-define` (build-time) | ✅ Kurulu |
| eyegames.net | `CRON_SECRET` | Vercel env | ⚠️ Kullanıcı doğrulamalı |
| eyegames.net | Supabase service-role key, BigQuery/App Store Connect API kimlik bilgileri | Vercel env (`.env.local` lokal) | ✅ Zaten kurulu, bu denetimde değiştirilmedi |
