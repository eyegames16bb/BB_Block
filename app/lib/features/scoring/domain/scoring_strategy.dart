/// Placement scoring (1 point per occupied cell) is universal across modes
/// and applied by the caller directly — only the per-line reward varies by
/// mode, which is what this strategy governs. Simultaneous or consecutive
/// line clears are never bonus-multiplied: the total for a multi-line clear
/// is `lineCount * pointsPerClearedLine(...)`, nothing extra.
abstract interface class ScoringStrategy {
  int pointsPerClearedLine({required int scoreBeforeClear});
}
