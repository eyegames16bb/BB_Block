import 'package:bb_block/features/scoring/domain/classic_scoring_strategy.dart';
import 'package:bb_block/features/scoring/domain/level_scoring_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClassicScoringStrategy', () {
    test('framed board awards 8 points per line', () {
      const strategy = ClassicScoringStrategy(hasFrame: true);
      expect(strategy.pointsPerClearedLine(scoreBeforeClear: 0), 8);
      expect(strategy.pointsPerClearedLine(scoreBeforeClear: 500), 8);
    });

    test('frameless board awards 9 points per line', () {
      const strategy = ClassicScoringStrategy(hasFrame: false);
      expect(strategy.pointsPerClearedLine(scoreBeforeClear: 0), 9);
    });
  });

  group('LevelScoringStrategy', () {
    const strategy = LevelScoringStrategy();

    test('awards 8 points per line below the 900 threshold', () {
      expect(strategy.pointsPerClearedLine(scoreBeforeClear: 0), 8);
      expect(strategy.pointsPerClearedLine(scoreBeforeClear: 899), 8);
    });

    test('awards 9 points per line at and above the 900 threshold', () {
      expect(strategy.pointsPerClearedLine(scoreBeforeClear: 900), 9);
      expect(strategy.pointsPerClearedLine(scoreBeforeClear: 1000), 9);
    });
  });
}
