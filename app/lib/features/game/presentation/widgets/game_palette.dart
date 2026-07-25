import 'package:flutter/widgets.dart';

/// Wood-themed colours for the play surface. Kept next to the board widgets
/// (not in the global theme) because they describe game-board materials
/// specifically, not app-wide chrome. Sampled directly from the hex values
/// in `Arayüz Örnek Görselin Html ve Css Kodları/css.txt` (the literal
/// reference mockup this HUD was redesigned to match "birebir" — see
/// CLAUDE.md) rather than eyeballed off the screenshot.
abstract final class GamePalette {
  /// `.grid-container` background — the dark recessed well the cells sit in.
  static const Color boardBackground = Color(0xFF3A1E0B);

  /// `.cell` background — visibly lighter than [boardBackground] so empty
  /// cells read as individual recessed slots, not a flat dark field.
  static const Color emptySlot = Color(0xFF4A2810);

  static const Color placedBlock = Color(0xFFDCAA6C);
  static const Color placedBlockEdge = Color(0xFFA1723D);

  /// A soft highlight along a placed/frame tile's top-left, simulating a
  /// raised bevel — mirrors the piece art's lighter top face in the
  /// reference instead of the flat single-tone chip drawn before.
  static const Color tileHighlight = Color(0x4DFFFFFF);

  static const Color frameBlock = Color(0xFFC79A61);
  static const Color frameBlockEdge = Color(0xFF8F6738);

  /// `.game-container`'s own gradient — the warm-wood bezel framing the
  /// grid, matching the margin between the board and the surrounding panel
  /// in the reference.
  static const Color bezelLight = Color(0xFF9E5D32);
  static const Color bezelDark = Color(0xFF6D3A19);

  /// `.icon-btn`/`.action-btn`'s gradient and border — the header/booster
  /// button chrome.
  static const Color woodButtonLight = Color(0xFFC4824D);
  static const Color woodButtonDark = Color(0xFF7D441E);
  static const Color woodButtonBorder = Color(0xFF4A250E);

  /// `.score`/`.powerup-btn`/`.piece-dock`'s shared dark-brown panel fill.
  static const Color panelDark = Color(0xFF4A250E);
  static const Color panelDarkBorder = Color(0xFF6D3A19);

  /// The solid (non-blurred) drop ledge under wood buttons — `box-shadow: 0
  /// Npx 0 #321808` in the reference, a flat "3D button" edge rather than a
  /// soft shadow.
  static const Color buttonLedge = Color(0xFF321808);

  static const Color previewValid = Color(0x6685C46A);
  static const Color previewInvalid = Color(0x66D46A5A);

  /// The crown/record badge's gold, brighter than the app-wide accent gold
  /// so it pops against the dark HUD chips specifically.
  static const Color recordGold = Color(0xFFF2B93B);

  /// `.progress-fill`'s gradient — brighter and warmer than [recordGold]
  /// alone, used for the Level Mode progress bar fill specifically.
  static const Color progressFillLight = Color(0xFFFCE07E);
  static const Color progressFillDark = Color(0xFFE69D37);
  static const Color progressTrack = Color(0xFF321808);

  static const double draggingSlotOpacity = 0.3;
}
