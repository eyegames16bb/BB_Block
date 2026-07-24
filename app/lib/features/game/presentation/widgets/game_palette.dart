import 'package:flutter/widgets.dart';

/// Wood-themed colours for the play surface. Kept next to the board widgets
/// (not in the global theme) because they describe game-board materials
/// specifically, not app-wide chrome.
abstract final class GamePalette {
  static const Color boardBackground = Color(0xFF3A2417);
  static const Color emptySlot = Color(0xFF4A2E1C);

  static const Color placedBlock = Color(0xFFCB8B4E);
  static const Color placedBlockEdge = Color(0xFF8A5A2E);

  static const Color frameBlock = Color(0xFFA9743F);
  static const Color frameBlockEdge = Color(0xFF7A4E28);

  static const Color previewValid = Color(0x6685C46A);
  static const Color previewInvalid = Color(0x66D46A5A);

  static const double draggingSlotOpacity = 0.3;
}
