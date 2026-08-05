# PERFORMANCE REPORT — BB Block

**Tarih:** 2026-08-05 · Kaynak: `MASTER_AUDIT_REPORT.md` Bölüm C'nin özeti. eyegames.net için ayrı bir
performans turu yapılmadı — Phase 1'in kendi taraması zaten `next/image`/`next/font` doğru kullanımını
ve CLS riski taşımayan görselleri doğrulamıştı, ek bir performans sorunu bulunmadı.

## Düzeltilen Bulgular

| # | Bulgu | Etki | Düzeltme |
|---|---|---|---|
| P1 | Kök widget (`BbBlockApp`) `PlayerProgress`'in TAMAMINI izliyordu, yalnızca `languageCode` için — herhangi bir skor/coin/level değişikliğinde TÜM aktif ekranı köke kadar yeniden inşa ediyordu. | HIGH | `ref.watch(...select(...))` ile daraltıldı |
| P2 | `_RoundOverlay` zafer DIŞINDAKİ her durumda da (Level Failed, Classic Game Over) bir `Newton` parçacık sistemi mount ediyordu, hiç kullanmadan. | MEDIUM | Yalnızca zaferde mount edilecek şekilde koşullandırıldı |
| P3/P4 | 3 görsel (rewarded-ad promo, home background, game/tutorial background) `cacheWidth`/`cacheHeight` vermeden native çözünürlükte decode ediliyordu. | MEDIUM/LOW | `MediaQuery` tabanlı cache boyutları eklendi (kırpma/fit davranışı değişmedi) |

## Bilinçli Olarak Ertelenen Bulgular (gerçek, ama riskli/geniş kapsamlı)

| # | Bulgu | Neden ertelendi |
|---|---|---|
| P5 | **En önemli erteleme.** Ana oyun ekranının `BoardGrid`'i (`enableParticles` varsayılan `true`) bir `Newton` parçacık sistemini TÜM round boyunca mount ediyor; paketin kendi `Ticker`'ı boşta bile her frame planlanıyor — cihazın gerçek idle/düşük-güç durumuna geçmesini engelliyor. `newton_particles` 0.3.0→0.4.1 changelog'u kontrol edildi, bu konuda hiçbir düzeltme yok. Tutorial ekranı zaten `enableParticles:false` kullanıyor ama asıl oyun ekranı (çok daha uzun süre çalışan) kullanmıyor. | Oyun içi efektler (toz patlaması/kıvılcım/konfeti) gerçek oynanışta aktif kullanılıyor — tutorial gibi bütünüyle kapatmak mümkün değil. Güvenli düzeltme paket fork/patch'i veya özel bir on-demand parçacık sistemi gerektiriyor. |
| P6 | `GameScreen` hem tüm `GameSession`'ı hem tüm `PlayerProgress`'i izliyor — tek-alanlık bir değişiklik bile koca alt ağacı yeniden inşa ediyor. | `GameScreen`'in ve çocuklarının imza yapısını genişçe değiştirmeyi gerektirir — riskli refactor. |
| P7 | `BoardGrid._onDragMove`, sürüklenen parça geçerli bir hücreye her girişinde tam board kopyası + satır tarama yapıyor (yalnızca önizleme rengi için). | Sürükle-bırak mantığının kalbine dokunuyor — dikkatli/izole bir tur gerektiriyor. |

## Doğrulama

Tüm P1-P4 değişiklikleri `flutter analyze` (temiz) + `flutter test` (170/170) ile doğrulandı. Ayrıca
Aşama 5'te GERÇEK bir release build (minify+obfuscate açık) alınıp emülatörde smoke-test edildi —
performans regresyonu YOK, ana menü + Level Mod oyun ekranı sorunsuz render oldu.

## Öneri (sonraki tur için)

P5, kod tabanının en somut kalan performans fırsatı — `Newton` paketinin sürekli çalışan `Ticker`'ı
gerçek cihazlarda (özellikle düşük-orta segment Android) pil tüketimi ve olası jank kaynağı olabilir.
Ayrı, odaklı bir görev olarak ele alınması önerilir.
