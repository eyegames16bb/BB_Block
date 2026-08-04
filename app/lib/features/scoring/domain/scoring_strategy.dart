/// Placement scoring (1 point per occupied cell) is universal across modes
/// and applied by the caller directly — only line-clear scoring varies by
/// mode, which is what this strategy governs.
abstract interface class ScoringStrategy {
  /// The full point value for clearing [lineCount] lines in the same move
  /// — already the total, not a per-line rate the caller multiplies
  /// further (the underlying table isn't linear). [scoreBeforeClear] lets
  /// Level Mode switch to its original flat-rate model once the 750-point
  /// threshold is passed.
  int pointsForClear({required int lineCount, required int scoreBeforeClear});

  /// Extra points added on top of [pointsForClear] when this clear lands
  /// within the mode's combo time window of the previous one (tracked by
  /// the caller — see `GameEngine`). Returns 0 where this mode/threshold
  /// doesn't grant a combo bonus at all.
  int comboBonusPoints({required int scoreBeforeClear});
}
