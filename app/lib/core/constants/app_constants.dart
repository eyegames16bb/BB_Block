abstract final class BoardConstants {
  static const int gridSize = 10;
  static const int piecesPerTurn = 3;
}

abstract final class ScoringConstants {
  static const int classicFramedLineScore = 8;
  static const int classicFramelessLineScore = 9;
  static const int levelPreThresholdLineScore = 8;
  static const int levelPostThresholdLineScore = 9;
}

abstract final class LevelModeConstants {
  static const int targetScore = 1000;
  static const int frameRemovalThreshold = 900;
}

abstract final class BoosterConstants {
  static const int defaultRotateCharges = 1;
  static const int defaultSwapCharges = 1;
  static const int defaultSingleCellRemoveCharges = 1;
}

abstract final class GoldKeyConstants {
  static const int levelsPerGoldKeyReward = 10;

  /// First-time balance for a fresh install. Spent keys don't come back on
  /// their own — the only way back to this count is a clean reinstall,
  /// since `PlayerProgress` is the single local save blob and there's no
  /// server-side account to restore from (see CLAUDE.md).
  static const int startingGoldKeyCount = 10;
}
