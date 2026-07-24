import 'package:bb_block/core/services/haptics/haptics_service.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/game/application/game_haptics.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invalid move is a light pulse', () {
    expect(
      hapticIntensityFor(const GameEvent.invalidMove()),
      HapticIntensity.light,
    );
  });

  test('placing a piece is a light selection tick', () {
    expect(
      hapticIntensityFor(const GameEvent.piecePlaced(placementPoints: 1)),
      HapticIntensity.selection,
    );
  });

  test('a single cleared line is medium, two or more is heavy', () {
    expect(
      hapticIntensityFor(
        const GameEvent.linesCleared(rows: [0], columns: [], linePoints: 9),
      ),
      HapticIntensity.medium,
    );
    expect(
      hapticIntensityFor(
        const GameEvent.linesCleared(
          rows: [0, 1],
          columns: [],
          linePoints: 18,
        ),
      ),
      HapticIntensity.heavy,
    );
    expect(
      hapticIntensityFor(
        const GameEvent.linesCleared(rows: [0], columns: [0], linePoints: 18),
      ),
      HapticIntensity.heavy,
    );
  });

  test('a tray refill stays silent to avoid a redundant double-pulse', () {
    expect(hapticIntensityFor(const GameEvent.trayRefilled()), isNull);
  });

  test('frame destruction and round end are heavy', () {
    expect(
      hapticIntensityFor(const GameEvent.frameDestroyed()),
      HapticIntensity.heavy,
    );
    expect(
      hapticIntensityFor(
        const GameEvent.roundEnded(outcome: RoundOutcome.classicGameOver()),
      ),
      HapticIntensity.heavy,
    );
  });

  test('boosters: rotate is a tick, swap and cell removal are medium', () {
    expect(
      hapticIntensityFor(const GameEvent.pieceRotated(trayIndex: 0)),
      HapticIntensity.selection,
    );
    expect(
      hapticIntensityFor(const GameEvent.traySwapped()),
      HapticIntensity.medium,
    );
    expect(
      hapticIntensityFor(
        const GameEvent.cellRemoved(
          position: GridPosition(row: 0, column: 0),
        ),
      ),
      HapticIntensity.medium,
    );
  });
}
