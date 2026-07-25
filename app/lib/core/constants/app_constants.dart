abstract final class BoardConstants {
  /// Level Mode's board, and Classic Mode's frameless board.
  static const int gridSize = 10;

  /// Classic Mode's board when played with the frame — deliberately
  /// smaller than [gridSize], per user instruction: framed Classic is a
  /// distinct, tighter puzzle from the frameless 10x10 variant.
  static const int classicFramedGridSize = 8;

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
  /// Charges of *each* booster granted for a single Level Mode round when
  /// the player spends a Gold Key at the start-of-round choice — not a
  /// persistent balance (see CLAUDE.md): unused charges are lost at round
  /// end, and nothing during the round can add more.
  static const int unlockedChargesPerRound = 1;
}

abstract final class GoldKeyConstants {
  static const int levelsPerGoldKeyReward = 10;

  /// First-time balance for a fresh install. Spent keys don't come back on
  /// their own — the only way back to this count is a clean reinstall,
  /// since `PlayerProgress` is the single local save blob and there's no
  /// server-side account to restore from (see CLAUDE.md).
  static const int startingGoldKeyCount = 10;
}
