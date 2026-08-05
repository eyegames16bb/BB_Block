# BUG REPORT TEMPLATE — BB Block + eyegames.net

Yeni bir hata bildirirken (kullanıcıdan gelen, kendi testinde bulunan, veya crash raporundan) bu
şablonu doldur — hem üretkenlik hem de gelecekteki bir Claude Code oturumunun/geliştiricinin hızlıca
bağlam kazanması için.

```markdown
## Özet
[Tek cümlede ne bozuluyor]

## Proje
- [ ] BB Block (Flutter oyunu)
- [ ] eyegames.net (website/admin panel)

## Platform / Ortam
- Cihaz/OS: [ör. Pixel 8, Android 15 / iPhone 15, iOS 18 / Chrome 130 masaüstü]
- Sürüm: [pubspec.yaml version veya git commit hash]
- Mod: [Klasik Çerçeveli / Klasik Çerçevesiz / Level Mod / N/A]

## Tekrar Üretme Adımları
1. ...
2. ...
3. ...

## Beklenen Davranış
[Ne olmalıydı]

## Gerçekleşen Davranış
[Ne oldu — ekran görüntüsü/video/logcat/console log eklenebilirse eklensin]

## Şiddet
- [ ] CRITICAL — oyun/site kullanılamaz hale geliyor, veri kaybı riski
- [ ] HIGH — önemli bir özellik çalışmıyor, geçici çözüm yok
- [ ] MEDIUM — özellik bozuk ama geçici çözüm var
- [ ] LOW — kozmetik, işlevi etkilemiyor

## İlgili Kod (biliniyorsa)
[dosya:satır — ör. lib/features/game/presentation/widgets/board_grid.dart:813]

## Ek Notlar
[CLAUDE.md'de bu alanla ilgili bilinen bir "Bilinen açık nokta" var mı? Varsa referans ver.]
```

## Bu Proje İçin Özel Notlar

- **BB Block**: `CLAUDE.md`'nin "Bilinen açık noktalar" bölümü zaten uzun bir liste tutuyor —
  yeni bir bug bildirmeden önce oradan kontrol et, zaten bilinen bir sınırlama olabilir.
- **eyegames.net**: `docs/TASKS.md` ve bu denetimin `MASTER_AUDIT_REPORT.md`'si (Bölüm F/G) bilinen
  durumları listeliyor.
- **Emülatör kararsızlığı**: BB Block geliştirme geçmişinde (CLAUDE.md) tekrarlayan bir emülatör
  çökme paterni belgeli (SwiftShader yazılım render'ı ile ilgili) — bir "crash" bildirirken önce
  gerçek cihazda da tekrarlanıp tekrarlanmadığını kontrol et, emülatöre özgü olabilir.
