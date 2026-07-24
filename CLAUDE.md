# BB Block

9x9 ahşap temalı blok bulmaca oyunu (iOS + Android). Oyuncular rastgele 3 poliomino parçasını 9x9 ızgaraya yerleştirir, tam satır/sütun oluşturarak puan kazanır. İki mod: **Klasik Mod** (serbest oynanış, Çerçeve VAR/YOK seçeneği) ve **Level Mod** (1000 puan hedefi, 900 puanda çerçeve kalkar).

Kaynak tasarım dokümanı: [`Dökümasyon Proje Tanımı.md`](./Dökümasyon%20Proje%20Tanımı.md). Referans görseller: `Arayüz Örnek Görseller/`, `Blok Parçaları Örnek Görseller/` — bunlar üretim varlığı değil, ilham/mockup amaçlıdır (bkz. "Bilinen açık noktalar").

## Teknoloji

Flutter (stable) + Dart, Clean Architecture, Feature-First klasör yapısı.

- **State**: Riverpod (`flutter_riverpod` + `riverpod_annotation`/`riverpod_generator`, codegen tabanlı). `get_it` kullanılmıyor — Riverpod tek başına DI konteyneri.
- **Routing**: `go_router`
- **Codegen**: `freezed` + `json_serializable` + `build_runner`
- **Lint**: `very_good_analysis` (`flutter_lints` değil — ikisi birlikte kullanılmaz). `public_member_api_docs` kuralı kapalı: yorum yazma kuralımız zaten "yalnızca non-obvious olan yerde" prensibine dayanıyor.
- **Local storage**: `shared_preferences` üzerinden tek JSON blob (`LocalGameSaveRepository`). Bilinçli olarak Isar/Hive değil — oyunun kalıcı veri ihtiyacı küçük (birkaç sayaç). `GameSaveRepository` arayüzü sayesinde ileride Isar/Hive/Drift'e geçiş yalnızca `features/persistence/data/` içinde kalır.
- **Cloud backend**: Supabase (karar verildi — açık kaynak/uzun vadeli tercih gerekçesiyle Firebase yerine). `google_mobile_ads` backend'den bağımsız olduğu için reklam tarafı etkilenmiyor.
- **Reklam**: `google_mobile_ads` (AdMob). `AdMobAdsService` şu an Google'ın herkese açık **test** ad unit ID'lerini kullanıyor — mağaza gönderiminden önce gerçek ID'lerle değiştirilmeli.
- **IAP**: `purchases_flutter` (RevenueCat)
- **Ses**: `audioplayers` (çakışan çoklu SFX + döngülü ambiyans)
- **Haptik**: `vibration`
- **Partikül**: `newton_particles`
- **İkon**: `phosphor_flutter`
- **Font**: Google Fonts — Fredoka (başlık/display) + Nunito (gövde), `google_fonts` paketiyle çalışma zamanında yükleniyor

## Mimari

```
lib/
  core/
    constants/     — büyü sayı yok: board boyutu, puan sabitleri, level eşiği burada
    theme/         — renk/tipografi token'ları
    routing/       — go_router
    services/      — Audio/Haptics/Ads: arayüz + implementasyon ayrı dosyalarda (SRP)
    utils/
  features/
    board/domain/           — Board, Cell, PieceShape, GridPosition; PlacementValidator, LineClearResolver
    piece_generation/domain — Factory Pattern: WeightedPieceGenerator (ağırlıklı rastgele + çözülebilirlik garantisi)
    scoring/domain           — Strategy Pattern: ClassicScoringStrategy / LevelScoringStrategy
    game_mode/domain         — Strategy Pattern: GameModeStrategy + RoundOutcome
    game_state/domain        — State Machine: GameState (Freezed sealed union)
    game_engine/domain       — Orkestrasyon: GameEngine + GameSession + GameEvent (saf Dart)
    booster/domain           — Command Pattern: Rotate/Swap/SingleCellRemove
    persistence/domain+data   — Repository Pattern: GameSaveRepository + local (SharedPreferences) impl
    persistence/application    — PlayerProgressController (yüksek skor/level/altın anahtar, kalıcı)
    game/application          — GameController (Riverpod Notifier) + GameLaunchConfig
    game/presentation         — GameScreen + BoardGrid/PieceTray/PieceView (oynanabilir döngü)
    home/presentation         — ana menü (mod seçimi + Çerçeve VAR/YOK diyaloğu)
```

Engine (board/scoring/piece_generation/booster/game_engine) UI'dan tamamen bağımsız — bu dosyaların hiçbiri `flutter/*` import etmez, yalnızca `application`/`presentation` katmanları eder. Bu ayrım korunmalı. UI, `GameController` üzerinden yalnızca `GameSession` state'ini okur ve intent metodları çağırır; kurallar widget katmanına sızmaz.

## Alınan mimari kararlar (kod yazılmadan önce netleşti)

1. **Backend**: Supabase.
2. **Undo**: Yok. Command Pattern yalnızca 3 tamamlayıcı için.
3. **Puanlama**: GDD metni aynen — Çerçeve VAR=8, Çerçeve YOK=9, Level&lt;900=8, Level≥900=9 puan/sıra. Kasıtlı zorluk dengesi olarak kabul edildi.
4. **Çerçeve kaldırma efekti**: GDD'nin "aynı animasyon" ifadesi yerine ayrı bir **Frame Destroy** efekti (parçalanma + toz + ayrı ses) kullanılacak — henüz implement edilmedi, `SoundEffect.frameDestroy` yalnızca tanımlı.
5. **Level ilerleme**: v1'de tek düzey davranış — her level aynı kurallarla çalışır, level numarası yalnızca ilerleme sayacı. Zorluk eğrisi tasarımı ertelendi (mimari `GameModeStrategy` ile buna hazır).
6. **Tamamlayıcı başlangıç sayıları**: Rotate=1, Swap=1, Single Cell Remove=1 (`BoosterConstants`). Daha fazlası ödüllü reklamla kazanılır.
7. **Combo**: Ekstra puan/çarpan yok. Çoklu sıra temizleme = `lineCount × pointsPerClearedLine`, doğrusal. "Combo"/"Multiple Line Complete" yalnızca ses/animasyon geri bildirimi olarak kalıyor, puanlamayı etkilemiyor.
8. **HUD "+" butonları**: Yok. Mockup'taki inline "+" butonları bilinçli olarak uygulanmıyor — tamamlayıcı yenileme ayrı bir akış (ödüllü reklam) üzerinden olacak, henüz UI'da tasarlanmadı.

## Bilinen açık noktalar (henüz kapatılmadı)

- Booster edge case: "Tek Nokta Silici" çerçeve hücresini hedefleyemez (kod bunu zaten uyguluyor, `SingleCellRemoveCommand`), ama bu davranış kullanıcıyla ayrıca teyit edilmedi.
- Asset lisansları: **Mixkit** SFX lisansının oyun içi kullanımı yasaklıyor olabileceği, **Zapsplat**'ın ücretsiz planda atıf zorunluluğu getirdiği tespit edildi — kullanılmadan önce manuel doğrulanmalı.
- Ses/görsel/font varlıkları henüz yok. `AudioService` implementasyonu `assets/audio/sfx/*.mp3` ve `assets/audio/ambient/background_loop.mp3` bekliyor — dosyalar eklenmeden `pubspec.yaml`'a asset kaydı yapılmadı.
- Org kimliği `com.bbblock` yer tutucudur — mağaza gönderiminden önce gerçek ters-domain ile değiştirilmeli (`app/android`, `app/ios` proje ayarları).
- Android SDK cmdline-tools eksik, lisanslar kabul edilmedi (`flutter doctor` bunu gösteriyor) — cihazda/emülatörde çalıştırmadan önce tamamlanmalı.
- Git kimliği bu depoya özel ayarlandı (`digitalsynclab-cpu` / `digitalsynclab@gmail.com`); henüz uzak depo (GitHub vb.) yok.
- **Booster UI yok**: Engine `rotatePiece`/`swapTray`/`removeCell` destekliyor ve `GameController` bunları açıyor, ama oyun ekranında henüz buton/etkileşim tasarlanmadı. Charge sayımı da app katmanında henüz yok (engine charge-agnostik).
- **Ses/haptik/animasyon henüz bağlı değil**: `GameController._apply` içindeki `events` şu an tüketilmiyor (yorumla işaretli extension point). UI tamamen `GameSession` state'iyle sürülüyor. Frame Destroy / line-clear animasyonları bekliyor.
- **Sürükle-bırak v1**: Parçanın (0,0) hücresi işaretçinin altındaki hücreye çapalanıyor (`pointerDragAnchorStrategy`) ve şekil tahtada kalacak şekilde clamp'leniyor. Kullanışlı ama parmağın altında kalıyor; ileride yukarı ofset/geliştirme yapılabilir.

## Komutlar

```bash
cd app
flutter pub get
dart run build_runner build   # .freezed.dart / .g.dart üretimi (--delete-conflicting-outputs artık gerekmiyor)
flutter analyze
flutter test
```

## Referans raporlar

Bu depo dışında, konuşma geçmişinde iki analiz artifact'i üretildi: proje envanteri + GDD tutarsızlıkları, ve mimari/teknoloji karar raporu (açık kaynak + asset araştırması dahil). Yeni bir oturumda bu dosyaları bulamazsan, kullanıcıdan bağlantıları isteyebilirsin.
