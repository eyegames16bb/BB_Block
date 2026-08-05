# SECURITY REPORT — BB Block + eyegames.net

**Tarih:** 2026-08-05 · Kaynak: `MASTER_AUDIT_REPORT.md` Bölüm A/B/D/F'nin güvenlik-odaklı özeti.
Tam gerekçeler/kod konumları için `MASTER_AUDIT_REPORT.md`'ye bakın — bu doküman yalnızca "güvenlik"
merceğinden bir konsolide görünüm.

## Durum Özeti

| Alan | Kritik | Yüksek | Orta | Düşük | Kalan aksiyon |
|---|---|---|---|---|---|
| BB Block (mobil güvenlik) | 1 (A1 — gerçek AdMob ID) | 0 | 0 | 0 | Kullanıcı: AdMob console'undan gerçek ID |
| BB Block (Game Security, Aşama 4) | 0 | 0 (G1 düzeltildi) | 0 | 0 | Yok — tümü düzeltildi/araştırılıp gereksiz bulundu |
| eyegames.net (Web Security, Aşama 1+6) | 0 | 0 (B1 kod-taraflı düzeltildi) | 0 | 0 | Kullanıcı: Vercel'de `CRON_SECRET` set etmek |

## Düzeltilmiş Güvenlik Bulguları (bu denetim sırasında)

1. **G1 [CRITICAL] — App Tracking Transparency hiç bağlanmamıştı.** `AdMobAdsService.init()` iOS'ta
   ATT onayından önce `MobileAds.instance.initialize()` çağırıyordu — gerçek bir App Store red riski.
   Düzeltildi: ATT durumu kontrol edilip gerekirse izin isteniyor, ancak sonra AdMob başlatılıyor.
2. **B1 [HIGH] — eyegames.net cron endpoint'i `CRON_SECRET` boşken sessizce kimliksiz çalışıyordu.**
   Artık `CRON_SECRET` tanımsızsa 500 dönüyor (fail-closed) — Vercel'de gerçekten set edilmesi hâlâ
   kullanıcı aksiyonu.
3. **S1 [HIGH] — eyegames.net admin paneli arama motorlarına tamamen açıktı.** `/admin`/`/admin/login`
   noindex değildi, `robots.ts` disallow etmiyordu. Düzeltildi ve `next build`+`next start`+`curl` ile
   uçtan uca doğrulandı.
4. **A3/G3 [HIGH/MEDIUM] — Android release build minify/obfuscate edilmiyordu.** R8/ProGuard +
   `--obfuscate --split-debug-info` etkinleştirildi, GERÇEK bir release build + emülatör smoke-test
   ile doğrulandı (64.0MB APK, sıfır crash).
5. **A2 [CRITICAL] — iOS Privacy Manifest tamamen eksikti.** Oluşturulup Xcode projesine bağlandı.
6. **W1 [LOW] — eyegames.net cron endpoint'i ham Supabase hata mesajını istemciye sızdırıyordu.**
   Jenerik hata mesajına çevrildi, sunucu tarafında loglanıyor.

## Araştırılıp "gerçek sorun değil" bulunan maddeler (BB Block, dürüst değerlendirme)

- **Yerel save verisi (skor/coin) düz metin, kurcalanabilir** — tek oyunculu, sunucu-otoriter değil,
  liderlik tablosu yok. Kendi kendini kandırmanın hiçbir başka oyuncuyu/geliri etkilemediği
  değerlendirildi. Checksum/şifreleme EKLENMEDİ — gerçek IAP bağlanana kadar gereksiz.
- **Root/jailbreak tespiti yok** — DRM/anti-cheat/gerçek-para IAP yüzeyi olmadığı için gerekmiyor.
- **TLS pinning yok** — finansal/PII veri hiç geçmiyor, sertifika rotasyon riskiyle orantısız olurdu.
- **Supabase `ad_views` anon INSERT rate-limit'siz (B2/G2)** — etki tavanı yalnızca "iç analytics
  panelini kirletme", PII/finansal risk yok. Üç mitigasyon seçeneği değerlendirilip "hiçbir şey
  yapmama" savunulabilir karar olarak seçildi (gerekçe `MASTER_AUDIT_REPORT.md` Bölüm F/D'de).

## Bekleyen Kullanıcı Aksiyonları

| Madde | Kim yapabilir |
|---|---|
| Gerçek AdMob App ID + ad-unit ID'leri (Android+iOS) | Yalnızca kullanıcı — AdMob console erişimi gerekli |
| Gerçek `applicationId`/`namespace` (`com.bbblock.bb_block` yerine) | Yalnızca kullanıcı — ürün kararı |
| Vercel Production'da `CRON_SECRET` set etmek | Yalnızca kullanıcı — Vercel hesap erişimi gerekli |
| iOS Privacy Manifest'in Xcode'un "Generate Privacy Report" aracıyla teyidi | Yalnızca kullanıcı — Mac/Xcode gerekli, bu denetim Windows'ta yapıldı |
