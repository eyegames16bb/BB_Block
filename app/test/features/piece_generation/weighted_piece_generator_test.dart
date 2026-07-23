import 'dart:math';

import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/services/placement_validator.dart';
import 'package:bb_block/features/piece_generation/domain/weighted_piece_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_fixtures.dart';

void main() {
  const validator = DefaultPlacementValidator();

  test('produces the requested number of pieces', () {
    final generator = WeightedPieceGenerator(random: Random(1));

    final batch = generator.nextBatch(board: Board.empty());

    expect(batch.length, 3);
  });

  test('guarantees the first piece fits the current board', () {
    // A board where the only empty cells are isolated singletons: no piece
    // larger than one cell can be placed, so the guarantee must select a
    // single-cell shape as the first piece.
    final board = boardFromRows([
      'X.X.X.X.X',
      'XXXXXXXXX',
      'X.X.X.X.X',
      'XXXXXXXXX',
      'X.X.X.X.X',
      'XXXXXXXXX',
      'X.X.X.X.X',
      'XXXXXXXXX',
      'X.X.X.X.X',
    ]);

    // Run many draws to defeat any lucky seeding.
    for (var seed = 0; seed < 50; seed++) {
      final generator = WeightedPieceGenerator(random: Random(seed));
      final batch = generator.nextBatch(board: board);

      expect(
        validator.hasAnyValidPlacement(board: board, shape: batch.first),
        isTrue,
        reason: 'first piece must be placeable (seed $seed)',
      );
    }
  });
}
