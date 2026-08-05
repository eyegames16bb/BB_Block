# STORE SUBMISSION GUIDE — BB Block

**Tarih:** 2026-08-05 · Adım adım gönderim süreci. Teknik ön koşullar için `ANDROID_RELEASE.md`/
`IOS_RELEASE.md`/`STORE_CHECKLIST.md`.

## Google Play

1. **Play Console hesabı** — geliştirici hesabı zaten var mı doğrula (bu denetimin kapsamı dışı).
2. **Uygulama oluştur** — gerçek `applicationId` seçildikten SONRA (geri dönüşü yok).
3. **App content** bölümünü doldur: gizlilik politikası URL'si, içerik derecelendirmesi anketi, hedef
   kitle, veri güvenliği formu (AdMob + Supabase `ad_views` beyan edilmeli).
4. **Store listing**: başlık, kısa/uzun açıklama, ekran görüntüleri, feature graphic, ikon.
5. **Production/Internal testing track** seç — ilk gönderim için Internal Testing önerilir (hızlı
   iterasyon, gerçek kullanıcı riski yok).
6. `ANDROID_RELEASE.md`'deki komutla üretilen `.aab` dosyasını yükle.
7. `mapping.txt`'i "App bundle explorer" → "Downloads" altında Deobfuscation dosyası olarak yükle.
8. İnceleme (genelde birkaç saat - birkaç gün).

## App Store Connect

1. **Apple Developer Program** üyeliği + App Store Connect erişimi doğrula.
2. **Yeni uygulama** oluştur — gerçek Bundle Identifier ile.
3. **App Privacy** formunu doldur — `ios/Runner/PrivacyInfo.xcprivacy` ile TUTARLI olmalı (ikisi ayrı
   sistemlerdir, biri kod-seviyesi manifest, diğeri App Store Connect'in kendi formu).
4. **TestFlight**'a ilk build'i yükle, iç test yap.
5. **App Store** sekmesinde: ekran görüntüleri, açıklama, anahtar kelimeler, kategori, yaş
   derecelendirmesi.
6. Gönder, incelemeyi bekle (genelde 24-48 saat, ilk gönderimde daha uzun sürebilir).

## Her İki Mağazada da Ortak Red Riskleri (bu proje özelinde)

- Test AdMob ID'leriyle gönderim → **KESİN RED**. Gerçek ID'ler girilmeden gönderme.
- (iOS) ATT izni istenmeden reklam SDK'sı çalışıyor gibi görünmesi → bu oturumda kod tarafı düzeltildi
  (G1), ama gerçek cihazda TEKRAR test edilmeli (bu denetim simülatörde/gerçek iOS cihazda test
  edemedi).
- Eksik/tutarsız gizlilik beyanları → `PrivacyInfo.xcprivacy` ile App Store Connect formunun
  BİRBİRİYLE TUTARLI olduğundan emin ol.
