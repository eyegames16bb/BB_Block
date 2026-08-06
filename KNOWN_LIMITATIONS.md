# KNOWN LIMITATIONS — BB Block + eyegames.net

**Tarih:** 2026-08-05 · Bu denetim boyunca (Aşama 1-9) tespit edilip BİLİNÇLİ OLARAK düzeltilmeyen
her şeyin tek bir listesi — ya kullanıcı verisi/kararı gerektirdiği ya da bu makinenin fiziksel
sınırları (Xcode/Mac yok) yüzünden. Hiçbiri "unutuldu" değil — hepsi kayıtlı ve gerekçeli.

## Yalnızca kullanıcının sağlayabileceği gerçek veri

1. **AdMob App ID + ad-unit ID'leri hâlâ Google'ın test değerleri** (`A1`, CRITICAL) — Android
   manifest, iOS Info.plist, `admob_ads_service.dart`. AdMob console'undan gerçek ID gerekiyor.
2. ~~`applicationId`/`namespace` hâlâ placeholder'ı~~ **ÇÖZÜLDÜ (2026-08-05, Codemagic kurulumu
   sırasında)** — kullanıcı "kullanıcı görmeyecekse fark etmez, sen seç" dedi, `com.eyegames.bbblock`
   seçildi (yayıncı EYE Games'in alan adına dayanan standart `.com` ters-domain konvansiyonu).
   `app/android/app/build.gradle.kts` (namespace+applicationId), Kotlin kaynak dizini
   (`com/bbblock/bb_block/` → `com/eyegames/bbblock/`), iOS `project.pbxproj`'daki TÜM
   `PRODUCT_BUNDLE_IDENTIFIER` girdileri (önceden Android'den FARKLI bir değerdi —
   `com.bbblock.bbBlock`, kendi ayrı bir tutarsızlıktı, bu düzeltmeyle ikisi de aynı oldu) ve
   `codemagic.yaml`'daki `PACKAGE_NAME`/`BUNDLE_ID`/`bundle_identifier` hep birlikte güncellendi.
   **Play Console'da uygulama kaydı bu isimle AÇILMADAN önce** yapıldı — yani bu, Play Console'un
   kalıcı/değiştirilemez paket-adı kısıtlamasına takılmadan yapılan doğru sıradaki bir değişiklik.
3. **Vercel Production'da `CRON_SECRET` set edilmemiş olabilir** (`B1`) — kod tarafı fail-closed
   yapıldı ama gerçek değerin Vercel'e girilmesi yalnızca kullanıcı yapabilir.

## Kullanıcı kararı bekleyen maddeler

4. **`purchases_flutter` (RevenueCat) kullanılmıyor** (`A7`) — kaldırılsın mı, planlanan bir IAP
   özelliği için mi tutulsun, kullanıcı "bilmiyorum" dedi, dokunulmadı.
5. **iOS hem portrait hem landscape açık** (`A13`) — 10x10 tahta oyunu için portrait-only kilit
   düşünülebilir, ama bu bir ürün/tasarım kararı, teknik zorunluluk değil.
6. **Aşama 8'in 11 UI/animasyon önerisi (U1-U11)** — hiçbiri uygulanmadı, kullanıcı hangilerini
   istediğine karar verecek. Tam liste: `MASTER_AUDIT_REPORT.md` Bölüm H.
7. **Supabase `ad_views` anon-INSERT rate-limit'siz** (`B2`/`G2`) — "hiçbir şey yapmama" bilinçli
   karar olarak seçildi (etki tavanı düşük), ama ileride iş kararına bağlıysa yeniden değerlendirilebilir.

## Bu makinenin fiziksel sınırları yüzünden doğrulanamayan

8. **iOS Privacy Manifest'in gerçek Xcode uyumluluğu doğrulanmadı.** `PrivacyInfo.xcprivacy`
   oluşturulup Xcode projesine mekanik olarak bağlandı (pbxproj syntax'ı script'le doğrulandı), ama
   gerçek bir `xcodebuild archive` + Xcode'un "Generate Privacy Report" aracı (yalnızca Mac'te) hiç
   çalıştırılamadı. Üçüncü parti SDK'ların (AdMob vb.) kendi bundle ettiği manifestlerle TAM uyum
   yalnızca bu araçla teyit edilebilir.
9. **iOS release build hiç denenmedi** — Android tarafı gerçek bir `flutter build apk --release
   --obfuscate --split-debug-info` + emülatör smoke-testiyle doğrulandı, iOS eşdeğeri
   (`flutter build ipa`) bu makinede mümkün değil.

## Bilinçli olarak ertelenen performans fırsatı

10. **P5 — Ana oyun ekranının `Newton` parçacık sistemi sürekli bir `Ticker` çalıştırıyor.** Gerçek
    bir bulgu, güvenli düzeltmesi paket-seviyesi bir çalışma (fork/patch) veya özel bir on-demand
    parçacık sistemi gerektiriyor — bu denetimin güvenli/düşük-riskli değişiklik sınırının dışında
    bırakıldı. Detay: `PERFORMANCE_REPORT.md`.

## Bu denetimin kapsamı dışında bırakılan (kullanıcı talimatı gereği)

11. **Gameplay/puanlama/level tasarımı/save sistemi** — kullanıcının açık talimatıyla hiç dokunulmadı.
12. **Mağaza listeleme içeriği** (ekran görüntüleri, açıklama metni, kategori seçimi, App Store/Play
    Store'un kendi inceleme formları) — bu denetimin kapsamında değil, ayrıca hazırlanmalı.
13. **Flutter tarafında derinlemesine bir erişilebilirlik (screen-reader/semantics) taraması** —
    eyegames.net tarafında yapıldı (Aşama 7), BB Block tarafında ayrı bir tur gerektirir.
