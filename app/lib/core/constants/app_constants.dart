abstract final class BoardConstants {
  /// Every board — Level Mode, and both Classic Mode variants — is this
  /// size. Framed boards (Level Mode always, Classic Mode when the player
  /// picks "Çerçeve Var") use this same grid size with a border ring of
  /// frame cells, leaving an 8x8 interior; frameless boards use the whole
  /// grid. There is no separate smaller board size — see CLAUDE.md.
  static const int gridSize = 10;

  static const int piecesPerTurn = 3;
}

abstract final class ScoringConstants {
  /// Points for clearing N lines in a single move (index 0 unused; a
  /// `lineCount` of 5 or more all clamp to index 5's value — the GDD-style
  /// spec this table comes from only goes up to 5). User instruction:
  /// Level Mode below its [LevelModeConstants.frameRemovalThreshold]
  /// frame-teardown threshold *and* Classic Mode with a frame share this
  /// exact table.
  static const List<int> standardClearPoints = [0, 8, 32, 48, 64, 100];

  /// Classic Mode without a frame — same shape, a flat step up per line
  /// count (10/40/60/80), same 100 cap at 5+.
  static const List<int> classicFramelessClearPoints = [0, 10, 40, 60, 80, 100];

  /// Level Mode's original flat per-line rate, unchanged — still what
  /// applies once [LevelModeConstants.frameRemovalThreshold] is passed
  /// (user instruction: "the current scoring system continues" there, the
  /// new table/combo bonus below don't apply post-threshold).
  static const int levelPostThresholdLineScore = 9;

  /// Flat bonus added on top of a clear's own table value when it lands
  /// within [comboWindow] of the previous clear — a simple "keep clearing
  /// quickly" reward, not a multiplier. Zero once Level Mode passes
  /// [LevelModeConstants.frameRemovalThreshold] (that mode's pre-existing
  /// linear scoring doesn't get combo bonuses either).
  static const int standardComboBonus = 8;
  static const int classicFramelessComboBonus = 10;
  static const Duration comboWindow = Duration(seconds: 5);
}

abstract final class LevelModeConstants {
  static const int targetScore = 1000;
  // Lowered from 900 (user instruction) — the frame comes down, and
  // scoring switches back to the original flat linear model (see
  // `LevelScoringStrategy`), earlier in the round now.
  static const int frameRemovalThreshold = 750;

  /// Bonus points (user instruction) for completing the specific
  /// row/column marked by the round's two star frame points (see
  /// `GameSession.starTargetRow`/`starTargetColumn`) — on top of that
  /// clear's own normal scoring, not instead of it.
  static const int starLineBonus = 250;
}

abstract final class BoosterConstants {
  /// Charges of *each* booster granted for a single Level Mode round when
  /// the player spends a Gold Key at the start-of-round choice — not a
  /// persistent balance (see CLAUDE.md): unused charges are lost at round
  /// end, and nothing during the round can add more.
  static const int unlockedChargesPerRound = 1;
}

/// User-facing terminology changed from "Altın Anahtar" (Gold Key) to
/// "Altın Coin" (Gold Coin) — user instruction, including a 100x rescale
/// of every reward/cost (1 key → 100 coins) to keep round numbers. The
/// internal identifiers here (class/field names, `grantGoldKey`,
/// `spendGoldKeyForBoosters`, etc.) deliberately still say "GoldKey" —
/// it's the exact same counter under the hood, just displayed under a new
/// name; renaming every symbol across the codebase was judged unnecessary
/// churn for a pure terminology change. See CLAUDE.md.
abstract final class GoldKeyConstants {
  static const int levelsPerGoldKeyReward = 10;

  /// First-time balance for a fresh install. Spent coins don't come back on
  /// their own — the only way back to this count is a clean reinstall,
  /// since `PlayerProgress` is the single local save blob and there's no
  /// server-side account to restore from (see CLAUDE.md). Scaled from the
  /// old 10-key balance (10 actions' worth at 1 key each) to the same
  /// ratio under the new 100-coin action cost.
  static const int startingGoldKeyCount = 1000;

  /// What a single Level Mode booster-unlock or Classic Mode continue
  /// costs (user instruction: both actions cost the same amount).
  static const int actionCostCoins = 100;

  /// Rewarded-ad payout (user instruction).
  static const int rewardedAdCoins = 100;

  /// Milestone bonus every [levelsPerGoldKeyReward] completed levels —
  /// scaled to match [actionCostCoins]'s new economy (was +1 key).
  static const int milestoneBonusCoins = 100;
}

/// Company credit links shown in Settings — user instruction. The
/// developer (HAYB) credit was removed again in a later session (user
/// instruction) — only the publisher credit remains.
abstract final class CreditsConstants {
  static const String publisherName = 'EYE Games';
  static const String publisherUrl = 'https://www.eyegames.net';
}
