# RELEASE NOTES — BB Block

Bu dosya, her yayınlanan sürüm için kullanıcıya-yönelik (Play Store/App Store "What's new") ve
dahili (teknik) notların tutulacağı şablondur. Henüz gerçek bir mağaza sürümü yayınlanmadığı için
ilk giriş bu denetimin production-hazırlık çalışmasını yansıtıyor — ileride her release'de yeni bir
giriş eklenmeli (en yeni en üstte).

---

## [Yayınlanmadı] — Production Audit (2026-08-05)

**Dahili (mağazada gösterilmez):**
- Android release build artık minify/obfuscate ediliyor (R8/ProGuard + `--obfuscate
  --split-debug-info`).
- iOS Privacy Manifest eklendi, App Tracking Transparency düzgün bağlandı.
- Performans: kök widget'ın gereksiz geniş state izleme kapsamı daraltıldı, gereksiz parçacık sistemi
  mount'ları kaldırıldı.
- Bkz. `CHANGELOG.md` (tam teknik değişiklik listesi), `PROJECT_SCORE.md` (genel değerlendirme).

**Kullanıcıya-yönelik (henüz mağazada değil, ilk gönderimde kullanılabilir taslak):**
> BB Block'a hoş geldiniz! 10x10 ahşap temalı bulmaca deneyiminizin tadını çıkarın — Klasik ve Level
> modlarında bloklarınızı yerleştirin, sıraları temizleyin, Altın Coin biriktirin.

---

## Şablon (her yeni release'de kopyalanıp doldurulmalı)

```
## [vX.Y.Z] — YYYY-AA-GG

**Kullanıcıya-yönelik:**
- ...

**Dahili:**
- ...
```
