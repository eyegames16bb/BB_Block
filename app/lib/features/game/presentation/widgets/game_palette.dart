import 'package:flutter/widgets.dart';

/// Wood-themed colours for the play surface. Kept next to the board widgets
/// (not in the global theme) because they describe game-board materials
/// specifically, not app-wide chrome. Sampled from the reference mockups in
/// `Arayüz Örnek Görseller/` — same light-wood family for the frame and the
/// bezel around the grid, a dark recessed brown for empty cells.
abstract final class GamePalette {
  static const Color boardBackground = Color(0xFF2A160C);
  static const Color emptySlot = Color(0xFF34200F);

  static const Color placedBlock = Color(0xFFDCAA6C);
  static const Color placedBlockEdge = Color(0xFFA1723D);

  static const Color frameBlock = Color(0xFFC79A61);
  static const Color frameBlockEdge = Color(0xFF8F6738);

  /// The light-wood bezel framing the whole grid, matching the mockups'
  /// margin between the board and the surrounding table.
  static const Color bezelLight = Color(0xFFD9B27C);
  static const Color bezelDark = Color(0xFF8C5E32);

  static const Color previewValid = Color(0x6685C46A);
  static const Color previewInvalid = Color(0x66D46A5A);

  /// The crown/record badge's gold, brighter than the app-wide accent gold
  /// so it pops against the dark HUD chips specifically.
  static const Color recordGold = Color(0xFFF2B93B);

  static const double draggingSlotOpacity = 0.3;
}
