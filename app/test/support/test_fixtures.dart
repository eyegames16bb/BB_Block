import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:bb_block/features/piece_generation/domain/piece_generator.dart';
import 'package:bb_block/features/scoring/domain/scoring_strategy.dart';

/// Builds a square board from ASCII rows: `.` empty, `#` frame, anything
/// else filled. Every row must have the same length as the row count.
Board boardFromRows(List<String> rows) {
  final size = rows.length;
  final cells = <CellState>[];
  for (final row in rows) {
    assert(row.length == size, 'Row "$row" is not $size wide');
    for (final char in row.split('')) {
      cells.add(switch (char) {
        '.' => CellState.empty,
        '#' => CellState.frame,
        _ => CellState.filled,
      });
    }
  }
  return Board(size: size, cells: cells);
}

PieceShape shapeById(PieceShapeId id) =>
    PieceShapeCatalog.all.firstWhere((shape) => shape.id == id);

/// A [PieceGenerator] that hands out pre-scripted batches in order, then
/// falls back to all-single-cell batches once the script is exhausted — so
/// engine tests stay fully deterministic.
class ScriptedPieceGenerator implements PieceGenerator {
  ScriptedPieceGenerator(this._batches);

  final List<List<PieceShape>> _batches;
  int _index = 0;

  @override
  List<PieceShape> nextBatch({required Board board, int count = 3}) {
    if (_index < _batches.length) return _batches[_index++];
    return List.filled(count, shapeById(PieceShapeId.single));
  }
}

/// A fully configurable [GameModeStrategy] so the engine's orchestration can
/// be tested in isolation from the real Classic/Level rules (which have their
/// own unit tests).
class FakeModeStrategy implements GameModeStrategy {
  FakeModeStrategy({
    required this.initialBoard,
    this.pointsPerLine = 10,
    this.frameThreshold,
    this.type = GameModeType.classic,
  });

  final Board initialBoard;
  final int pointsPerLine;
  final int? frameThreshold;

  @override
  final GameModeType type;

  @override
  ScoringStrategy get scoringStrategy => _FixedScoring(pointsPerLine);

  @override
  Board createInitialBoard() => initialBoard;

  @override
  bool shouldRemoveFrameAt(int score) =>
      frameThreshold != null && score >= frameThreshold!;

  @override
  RoundOutcome evaluateOutcome({
    required int currentScore,
    required bool hasAnyValidPlacement,
  }) =>
      hasAnyValidPlacement
          ? const RoundOutcome.ongoing()
          : const RoundOutcome.classicGameOver();
}

class _FixedScoring implements ScoringStrategy {
  const _FixedScoring(this.pointsPerLine);

  final int pointsPerLine;

  @override
  int pointsPerClearedLine({required int scoreBeforeClear}) => pointsPerLine;
}
