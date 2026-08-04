import 'package:bb_block/features/scoring/domain/classic_scoring_strategy.dart';
import 'package:bb_block/features/scoring/domain/level_scoring_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClassicScoringStrategy', () {
    group("framed board — shares Level Mode's pre-threshold table", () {
      const strategy = ClassicScoringStrategy(hasFrame: true);

      test('awards the table value per line count, regardless of score', () {
        expect(
          strategy.pointsForClear(lineCount: 1, scoreBeforeClear: 0),
          8,
        );
        expect(
          strategy.pointsForClear(lineCount: 2, scoreBeforeClear: 500),
          32,
        );
        expect(strategy.pointsForClear(lineCount: 3, scoreBeforeClear: 0), 48);
        expect(strategy.pointsForClear(lineCount: 4, scoreBeforeClear: 0), 64);
        expect(
          strategy.pointsForClear(lineCount: 5, scoreBeforeClear: 0),
          100,
        );
      });

      test('clamps 6+ simultaneous lines to the 5-line value', () {
        expect(
          strategy.pointsForClear(lineCount: 8, scoreBeforeClear: 0),
          100,
        );
      });

      test('grants an 8-point combo bonus', () {
        expect(strategy.comboBonusPoints(scoreBeforeClear: 0), 8);
      });
    });

    group('frameless board — its own higher table', () {
      const strategy = ClassicScoringStrategy(hasFrame: false);

      test('awards the frameless table value per line count', () {
        expect(
          strategy.pointsForClear(lineCount: 1, scoreBeforeClear: 0),
          10,
        );
        expect(strategy.pointsForClear(lineCount: 2, scoreBeforeClear: 0), 40);
        expect(strategy.pointsForClear(lineCount: 3, scoreBeforeClear: 0), 60);
        expect(strategy.pointsForClear(lineCount: 4, scoreBeforeClear: 0), 80);
        expect(
          strategy.pointsForClear(lineCount: 5, scoreBeforeClear: 0),
          100,
        );
      });

      test('grants a 10-point combo bonus', () {
        expect(strategy.comboBonusPoints(scoreBeforeClear: 0), 10);
      });
    });
  });

  group('LevelScoringStrategy', () {
    const strategy = LevelScoringStrategy();

    group('below the 750-point threshold — the new table', () {
      test('awards the table value per line count', () {
        expect(strategy.pointsForClear(lineCount: 1, scoreBeforeClear: 0), 8);
        expect(
          strategy.pointsForClear(lineCount: 2, scoreBeforeClear: 749),
          32,
        );
        expect(strategy.pointsForClear(lineCount: 3, scoreBeforeClear: 0), 48);
        expect(strategy.pointsForClear(lineCount: 4, scoreBeforeClear: 0), 64);
        expect(
          strategy.pointsForClear(lineCount: 5, scoreBeforeClear: 0),
          100,
        );
      });

      test('grants an 8-point combo bonus', () {
        expect(strategy.comboBonusPoints(scoreBeforeClear: 0), 8);
        expect(strategy.comboBonusPoints(scoreBeforeClear: 749), 8);
      });
    });

    group('at and above the 750-point threshold — original flat rate', () {
      test('awards 9 points per line, linearly, table ignored', () {
        expect(
          strategy.pointsForClear(lineCount: 1, scoreBeforeClear: 750),
          9,
        );
        expect(
          strategy.pointsForClear(lineCount: 2, scoreBeforeClear: 750),
          18,
        );
        expect(
          strategy.pointsForClear(lineCount: 5, scoreBeforeClear: 1000),
          45,
        );
      });

      test('grants no combo bonus once the threshold is passed', () {
        expect(strategy.comboBonusPoints(scoreBeforeClear: 750), 0);
        expect(strategy.comboBonusPoints(scoreBeforeClear: 1000), 0);
      });
    });
  });
}
