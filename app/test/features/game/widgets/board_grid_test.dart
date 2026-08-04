// `BoardGrid` now wraps its grid in a `Newton` particle overlay (dust burst
// on line clear / frame teardown — see wood_dust_effect.dart), and Newton
// runs a continuous Ticker for as long as it's mounted, regardless of
// whether any effect is active. That means `pumpAndSettle()` never
// terminates here (it waits for zero scheduled frames, which never happens)
// — every settle below is a bounded `pump(duration)` instead, long enough
// to run any of this file's animations (longest is the ~1s "Block Place"
// Game Feel sequence, see place_sequence.dart) to completion in one shot.
import 'dart:math' as math;

import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/game/presentation/widgets/board_grid.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/piece_tray.dart';
import 'package:bb_block/features/game/presentation/widgets/piece_view.dart';
import 'package:bb_block/features/game/presentation/widgets/place_sequence.dart';
import 'package:bb_block/features/game/presentation/widgets/wood_tile.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newton_particles/newton_particles.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../support/fake_audio_service.dart';
import '../../../support/fake_haptics_service.dart';
import '../../../support/test_fixtures.dart';

void main() {
  Widget harness({
    required Widget boardGrid,
  }) =>
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Draggable<int>(
                  data: 0,
                  feedback: SizedBox(width: 4, height: 4),
                  child: SizedBox(
                    key: Key('drag-source'),
                    width: 40,
                    height: 40,
                    child: ColoredBox(color: Colors.red),
                  ),
                ),
                Expanded(child: boardGrid),
              ],
            ),
          ),
        ),
      );

  Future<void> dragOnto(WidgetTester tester, Offset target) async {
    final source = tester.getCenter(find.byKey(const Key('drag-source')));
    final gesture = await tester.startGesture(source);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets(
      'a drop that lands on an already-filled cell still reaches onPlace — '
      'the widget must not silently swallow a rejected drop', (tester) async {
    final board = boardFromRows(['X..', '...', '...']);
    final tray = [TrayPiece(shape: shapeById(PieceShapeId.single))];
    var placeCalls = 0;

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(
          board: board,
          tray: tray,
          onPlace: (trayIndex, anchor) => placeCalls++,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final boardTopLeft = tester.getTopLeft(find.byType(BoardGrid));
    // Comfortably inside the already-filled (0,0) cell.
    await dragOnto(tester, boardTopLeft + const Offset(15, 15));

    expect(placeCalls, 1);
  });

  testWidgets('a drop onto empty space also reaches onPlace', (tester) async {
    final board = boardFromRows(['...', '...', '...']);
    final tray = [TrayPiece(shape: shapeById(PieceShapeId.single))];
    var placeCalls = 0;

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(
          board: board,
          tray: tray,
          onPlace: (trayIndex, anchor) => placeCalls++,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final boardTopLeft = tester.getTopLeft(find.byType(BoardGrid));
    await dragOnto(tester, boardTopLeft + const Offset(15, 15));

    expect(placeCalls, 1);
  });

  testWidgets(
      'dragging over a spot that would complete a line highlights that '
      'whole line in bold yellow before the drop (user instruction: '
      'preview a completing line, not just a valid one)', (tester) async {
    final board = boardFromRows(['XX.', '...', '...']);
    final tray = [TrayPiece(shape: shapeById(PieceShapeId.single))];

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(board: board, tray: tray, onPlace: (_, _) {}),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final boardRect = tester.getRect(find.byType(BoardGrid));
    final cellSize = boardRect.width / 3;
    // The only empty cell in row 0 — dropping the single-cell piece here
    // completes that row.
    final target = Offset(
      boardRect.left + 2.5 * cellSize,
      boardRect.top + 0.5 * cellSize,
    );

    final source = tester.getCenter(find.byKey(const Key('drag-source')));
    final gesture = await tester.startGesture(source);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 50));

    final highlight = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          (widget.decoration as BoxDecoration?)?.color ==
              GamePalette.lineClearHighlight.withValues(alpha: 0.55),
    );
    // All 3 cells of row 0 — including the two already-filled ones the
    // piece itself doesn't occupy — read as part of the completing line.
    expect(highlight, findsNWidgets(3));

    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
      'hovering over a spot that is valid but would *not* complete a line '
      'shows no yellow highlight', (tester) async {
    final board = boardFromRows(['...', '...', '...']);
    final tray = [TrayPiece(shape: shapeById(PieceShapeId.single))];

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(board: board, tray: tray, onPlace: (_, _) {}),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final boardTopLeft = tester.getTopLeft(find.byType(BoardGrid));
    final source = tester.getCenter(find.byKey(const Key('drag-source')));
    final gesture = await tester.startGesture(source);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(boardTopLeft + const Offset(15, 15));
    await tester.pump(const Duration(milliseconds: 50));

    final highlight = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          (widget.decoration as BoxDecoration?)?.color ==
              GamePalette.lineClearHighlight.withValues(alpha: 0.55),
    );
    expect(highlight, findsNothing);

    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
      'a cell that transitions to filled (a real placement) renders with a '
      'pop-in scale animation', (tester) async {
    final emptyBoard = boardFromRows(['...', '...', '...']);
    final filledBoard = boardFromRows(['X..', '...', '...']);

    await tester.pumpWidget(
      harness(
        boardGrid:
            BoardGrid(board: emptyBoard, tray: const [], onPlace: (_, _) {}),
      ),
    );
    await tester.pumpWidget(
      harness(
        boardGrid:
            BoardGrid(board: filledBoard, tray: const [], onPlace: (_, _) {}),
      ),
    );

    expect(find.byType(PlaceSequence), findsOneWidget);
  });

  testWidgets(
      'a cell already filled the first time the board appears skips the '
      "pop-in — user-reported crash: the tutorial's hand-built boards start "
      'with several pre-filled cells, and mounting that many simultaneous '
      'pop-in springs at once was enough concurrent animation load to '
      'crash a software-rendered emulator outright', (tester) async {
    final board = boardFromRows(['X..', '...', '...']);

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(board: board, tray: const [], onPlace: (_, _) {}),
      ),
    );

    expect(find.byType(PlaceSequence), findsNothing);
    expect(find.byType(WoodTile), findsOneWidget);
  });

  testWidgets(
      'a step-scoped key forces a fresh mount for a new pre-filled board — '
      "regression: the tutorial's step 3 board alone starts with 18 "
      'pre-filled cells (a full row+column cross) that its step 2 board '
      "(completely empty) never had. Without a key change, BoardGrid's "
      'same State (and its `_initiallyFilled` snapshot frozen from an '
      'earlier step) survives the transition, so the empty→filled diff '
      'would fire 18 simultaneous "Block Place" pop-ins (54 '
      'AnimationControllers) instead of the plain static tiles a '
      'genuinely fresh board deserves — worse than the original '
      'pre-filled-cell crash this mechanism exists to prevent',
      (tester) async {
    final emptyBoard = boardFromRows(List.filled(10, '.' * 10));
    final crossFilled = <GridPosition>{
      for (var i = 0; i < 10; i++) ...[
        GridPosition(row: 5, column: i),
        GridPosition(row: i, column: 5),
      ],
    }..remove(const GridPosition(row: 5, column: 5));
    final crossBoard = boardFromRows(
      List.generate(
        10,
        (row) => List.generate(
          10,
          (col) => crossFilled.contains(GridPosition(row: row, column: col))
              ? 'X'
              : '.',
        ).join(),
      ),
    );

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(
          key: const ValueKey(1),
          board: emptyBoard,
          tray: const [],
          onPlace: (_, _) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(
          key: const ValueKey(2),
          board: crossBoard,
          tray: const [],
          onPlace: (_, _) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // A fresh key means this is a genuine first mount for this board, not
    // a `didUpdateWidget` transition — every pre-filled cell should render
    // as a plain static tile, none as an animated pop-in.
    expect(find.byType(PlaceSequence), findsNothing);
    expect(find.byType(WoodTile), findsNWidgets(crossFilled.length));
  });

  testWidgets(
      'a cleared cell keeps rendering its wood tile briefly, then '
      'disappears once the break animation ends', (tester) async {
    final filledBoard = boardFromRows(['X..', '...', '...']);
    final clearedBoard = boardFromRows(['...', '...', '...']);

    await tester.pumpWidget(
      harness(
        boardGrid:
            BoardGrid(board: filledBoard, tray: const [], onPlace: (_, _) {}),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(
          board: clearedBoard,
          tray: const [],
          onPlace: (_, _) {},
        ),
      ),
    );

    // Mid-animation: the board already reports the cell empty, but its
    // wood tile is still on screen, fading/bursting out.
    await tester.pump();
    expect(find.byType(WoodTile), findsOneWidget);

    // Once the break animation completes, the overlay removes itself.
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(WoodTile), findsNothing);
  });

  testWidgets(
      'a completing line flashes bold yellow at the start of its break, '
      'then fades before the break ends (user instruction)', (tester) async {
    final filledBoard = boardFromRows(['X..', '...', '...']);
    final clearedBoard = boardFromRows(['...', '...', '...']);

    await tester.pumpWidget(
      harness(
        boardGrid:
            BoardGrid(board: filledBoard, tray: const [], onPlace: (_, _) {}),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(
          board: clearedBoard,
          tray: const [],
          onPlace: (_, _) {},
        ),
      ),
    );

    // Just after the clear starts: the yellow flash should be present and
    // essentially fully opaque.
    await tester.pump();
    final flash = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          (widget.decoration as BoxDecoration?)?.color ==
              GamePalette.lineClearHighlight.withValues(alpha: 0.75),
    );
    expect(flash, findsOneWidget);

    // Well before the break animation ends, the flash has already faded
    // out (front-loaded into the first ~40% of the break).
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Opacity &&
            widget.opacity == 0.0 &&
            widget.child is DecoratedBox,
      ),
      findsWidgets,
    );
  });

  testWidgets(
      'frame teardown keeps rendering frame tiles briefly, distinctly from '
      'an ordinary line clear', (tester) async {
    final framed = boardFromRows(['###', '#.#', '###']);
    final frameless = boardFromRows(['...', '...', '...']);

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(board: framed, tray: const [], onPlace: (_, _) {}),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpWidget(
      harness(
        boardGrid:
            BoardGrid(board: frameless, tray: const [], onPlace: (_, _) {}),
      ),
    );

    // Mid-animation: the border cells are gone from the board data, but
    // their (frame) wood tiles are still on screen, breaking outward.
    await tester.pump();
    expect(
      find.byWidgetPredicate((widget) => widget is WoodTile && widget.isFrame),
      findsWidgets,
    );

    // Once the (longer, staggered) break animation fully completes, every
    // overlay has removed itself.
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.byWidgetPredicate((widget) => widget is WoodTile && widget.isFrame),
      findsNothing,
    );
  });

  testWidgets(
      'renders the two star icons at the opposite frame points for a row '
      'target, and none for a column target on a different board '
      '(user instruction: Level Mode star bonus markers)', (tester) async {
    final board = Board.framed();

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(
          board: board,
          tray: const [],
          onPlace: (_, _) {},
          starTargetRow: 4,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final stars = find.byWidgetPredicate(
      (widget) => widget is Icon && widget.icon == PhosphorIconsFill.star,
    );
    expect(stars, findsNWidgets(2));

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(
          board: board,
          tray: const [],
          onPlace: (_, _) {},
        ),
      ),
    );

    // Mid-breakaway: the star bonus was just consumed (starTargetRow went
    // to null), but the icons are still on screen for one more animation
    // cycle — falling/fading away exactly like an ordinary line clear does
    // (user instruction), not vanishing outright.
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Icon && widget.icon == PhosphorIconsFill.star,
      ),
      findsNWidgets(2),
    );

    // Once the break animation completes, both stars are gone for good —
    // and the frame cells themselves are still all there, completely
    // untouched by this animation (only the star icons ever animated).
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Icon && widget.icon == PhosphorIconsFill.star,
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate((widget) => widget is WoodTile && widget.isFrame),
      findsNWidgets(board.size * 4 - 4),
    );
  });

  group('real PieceTray drag reach (regression: horizontal/single pieces '
      "couldn't reach a frameless board's last row)", () {
    // A fixed board footprint — exactly how `GameScreen` sizes things (a
    // single precomputed `boardSide`/`cellSize` shared by both `BoardGrid`
    // and `PieceTray`'s `dragCellSize`), avoiding a circular layout: an
    // `Expanded`+`AspectRatio` board whose size depends on the tray's own
    // height, which itself depends on a `cellSize` measured from that same
    // board, never converges to one stable answer across two `pumpWidget`
    // passes — it was the actual cause of an earlier, wrong "off by a
    // column" failure here, not a bug in the fix under test.
    const boardSide = 480.0;
    const cellSize = boardSide / 10;

    // The default 800x600 test surface fit board+tray comfortably at the
    // old, sub-1-cell drag lift, but `GamePalette.dragLiftPixels` (a FIXED
    // 0.4-inch/64px gap now, not cell-relative — user instruction) can
    // exceed a small cell size — reaching the last row now requires the
    // raw pointer to travel further past the board's bottom edge than the
    // default surface leaves room for below the tray. A taller surface
    // gives that room back without changing anything about the geometry
    // under test.
    void useTallSurface(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [
          audioServiceProvider.overrideWithValue(FakeAudioService()),
          hapticsServiceProvider.overrideWithValue(FakeHapticsService()),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    Widget realHarness(
      ProviderContainer c,
      Widget boardGrid,
      List<TrayPiece> tray,
      Board board,
    ) =>
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    width: boardSide,
                    height: boardSide,
                    child: boardGrid,
                  ),
                  SizedBox(
                    height: cellSize * 2.2,
                    child: PieceTray(
                      tray: tray,
                      dragCellSize: cellSize,
                      board: board,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

    // Mirrors production's `dragAnchorStrategy` (`piece_tray.dart`) exactly:
    // the Hidden Anchor Point (HN) — the shape's own bounding-box
    // bottom-center — sits `GamePalette.dragLiftPixels` above the raw
    // pointer, centered horizontally on it. Since `BoardGrid._onDragMove`
    // reads the feedback's reported top-left (`DragTargetDetails.offset`)
    // as the shape's top-left cell corner, solving for the pointer that
    // puts that top-left at a given `feedbackTopLeft` is just the inverse
    // of production's own formula:
    //   pointer = feedbackTopLeft + (feedbackWidth/2, liftPixels+feedbackHeight)
    // `verticalBias` (0=cell's top edge, 1=its bottom edge) picks where
    // within the target cell `feedbackTopLeft` lands — 0.5 (the default)
    // keeps comfortably inside the cell for the ordinary reach tests;
    // pushing it close to 1 (as the "just past the visible board" test
    // below does) requires the largest possible pointer displacement past
    // the board's own bottom edge, exercising the invisible extra-reach
    // strip specifically rather than the ordinary `DragTarget`.
    //
    // `BoardGrid`'s own `DragTarget` (the thing that actually has to be
    // hit-tested) sits inset from the outer board box by its
    // border+padding, so its real content size is a little smaller than
    // `boardSide` — measuring it directly (rather than assuming `cellSize`
    // applies to it too) is what an earlier, wrong "always lands empty"
    // failure here turned out to be.
    Future<void> realDragOnto(
      WidgetTester tester,
      GridPosition target,
      PieceShape shape, {
      double verticalBias = 0.5,
    }) async {
      final source = tester.getCenter(find.byType(Draggable<int>));
      // `board_grid.dart` now has a second, invisible `DragTarget` strip
      // below the board (extra reach margin — see its own doc comment),
      // so `find.byType(DragTarget<int>)` matches two; `.first` is always
      // the real board's own one (declared first in the widget tree).
      final dragTargetRect = tester.getRect(
        find.byType(DragTarget<int>).first,
      );
      final innerCellSize = dragTargetRect.width / 10;

      final shapeRows =
          shape.cells.map((cell) => cell.row).reduce(math.max) + 1;
      final shapeColumns =
          shape.cells.map((cell) => cell.column).reduce(math.max) + 1;
      final feedbackWidth = shapeColumns * cellSize;
      final feedbackHeight = shapeRows * cellSize;

      final feedbackTopLeft = Offset(
        dragTargetRect.left + (target.column + 0.5) * innerCellSize,
        dragTargetRect.top + (target.row + verticalBias) * innerCellSize,
      );
      final pointerTarget = feedbackTopLeft +
          Offset(
            feedbackWidth / 2,
            GamePalette.dragLiftPixels + feedbackHeight,
          );

      final gesture = await tester.startGesture(source);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(pointerTarget);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets(
        'a single-cell piece reaches row 9 (the very last row) of a 10x10 '
        'frameless board', (tester) async {
      useTallSurface(tester);
      final board = boardFromRows(List.filled(10, '.' * 10));
      final shape = shapeById(PieceShapeId.single);
      final tray = [TrayPiece(shape: shape)];
      final placedAt = <GridPosition>[];

      await tester.pumpWidget(
        realHarness(
          container(),
          BoardGrid(
            board: board,
            tray: tray,
            onPlace: (_, anchor) => placedAt.add(anchor),
          ),
          tray,
          board,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await realDragOnto(tester, const GridPosition(row: 9, column: 5), shape);

      expect(placedAt, [const GridPosition(row: 9, column: 5)]);
    });

    testWidgets(
        'a horizontal 3-line piece reaches row 9 of a 10x10 frameless board',
        (tester) async {
      useTallSurface(tester);
      final board = boardFromRows(List.filled(10, '.' * 10));
      final shape = shapeById(PieceShapeId.triominoLineHorizontal);
      final tray = [TrayPiece(shape: shape)];
      final placedAt = <GridPosition>[];

      await tester.pumpWidget(
        realHarness(
          container(),
          BoardGrid(
            board: board,
            tray: tray,
            onPlace: (_, anchor) => placedAt.add(anchor),
          ),
          tray,
          board,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await realDragOnto(tester, const GridPosition(row: 9, column: 3), shape);

      expect(placedAt, [const GridPosition(row: 9, column: 3)]);
    });

    testWidgets(
        'row 9 is reachable even landing just past the visible board — '
        'regression: the offset-shrink fix alone left a window that '
        'shrinks proportionally with cell size, so on a real (narrow) '
        "phone's much smaller cells it was only a few pixels — well "
        'within normal touch imprecision, so it still failed in '
        'practice. The extra invisible reach strip below the board '
        '(this test targets a point inside *only* that strip, past the '
        "board's own bottom edge) is what makes it robust regardless of "
        'screen size', (tester) async {
      useTallSurface(tester);
      final board = boardFromRows(List.filled(10, '.' * 10));
      final shape = shapeById(PieceShapeId.single);
      final tray = [TrayPiece(shape: shape)];
      final placedAt = <GridPosition>[];

      await tester.pumpWidget(
        realHarness(
          container(),
          BoardGrid(
            board: board,
            tray: tray,
            onPlace: (_, anchor) => placedAt.add(anchor),
          ),
          tray,
          board,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Biased toward row 9's own bottom edge — the largest possible
      // pointer displacement past the board's visible bottom edge, only
      // reachable via the invisible extra-reach strip.
      await realDragOnto(
        tester,
        const GridPosition(row: 9, column: 5),
        shape,
        verticalBias: 0.95,
      );

      expect(placedAt, [const GridPosition(row: 9, column: 5)]);
    });

    testWidgets(
        "the floating drag image moves by exactly the pointer's own delta "
        'when crossing a cell boundary — regression: a previous "magnetic '
        'snap" pull nudged the feedback toward the cell it was hovering, '
        'which read as the piece momentarily sticking/slowing every time it '
        'crossed into a new cell (user report: "sanki o kareye '
        'yerleşecekmiş gibi hissediliyor... görünmeyen mıknatıslar '
        'tarafından tutuluyormuş gibi"). The fix removed that pull outright '
        '— this asserts the floating piece now tracks the raw finger with '
        'no extra offset at all, even right at a cell boundary crossing',
        (tester) async {
      useTallSurface(tester);
      final board = boardFromRows(List.filled(10, '.' * 10));
      final shape = shapeById(PieceShapeId.single);
      final tray = [TrayPiece(shape: shape)];

      await tester.pumpWidget(
        realHarness(
          container(),
          BoardGrid(board: board, tray: tray, onPlace: (_, _) {}),
          tray,
          board,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final source = tester.getCenter(find.byType(Draggable<int>));
      final gesture = await tester.startGesture(source);
      // Long enough for the pick-up spring (~130-150ms) to fully settle,
      // so its scale stays constant across both measurements below — only
      // the drag's own translation should differ between them.
      await tester.pump(const Duration(milliseconds: 300));

      Offset feedbackTopLeft() => tester.getTopLeft(
            find.byWidgetPredicate(
              (widget) => widget is PieceView && widget.cellSize == cellSize,
            ),
          );

      final before = feedbackTopLeft();
      // A move comfortably within a single cell, well clear of any board
      // edge, then a second move exactly one cell size further right —
      // guaranteed to cross into the next column.
      final dragTargetRect = tester.getRect(
        find.byType(DragTarget<int>).first,
      );
      await gesture.moveTo(
        Offset(dragTargetRect.left + cellSize * 3.5, source.dy),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final afterFirstMove = feedbackTopLeft();

      await gesture.moveBy(const Offset(cellSize, 0));
      await tester.pump(const Duration(milliseconds: 16));
      final afterCrossing = feedbackTopLeft();

      await gesture.up();
      await tester.pump(const Duration(seconds: 1));

      expect(before, isNot(equals(afterFirstMove)));
      // The tilt (a small rotation, purely a function of pointer delta —
      // see `DragFeelController`) can shift the measured top-left by a
      // sub-pixel amount, so this allows a small tolerance — anything near
      // `cellSize` (tens of pixels) would fail it, which is what the old
      // "up to 8px" magnetic pull would have done.
      final dx = afterCrossing.dx - afterFirstMove.dx;
      expect(dx, closeTo(cellSize, 1.5));
    });

    testWidgets(
        'dragging the piece well past the board (toward the tray) never '
        'reaches onPlace, even though the drop still lands inside the '
        "invisible extra-reach strip — regression: the strip's own "
        'DragTarget used to be the only thing in that region, and it '
        "always clamped an out-of-range position onto the board's own "
        'last row instead of recognizing the piece had left the board '
        'entirely (user report: dropping a piece back onto the tray still '
        'made it look like it was about to land at the bottom of the '
        'board)', (tester) async {
      useTallSurface(tester);
      final board = boardFromRows(List.filled(10, '.' * 10));
      final shape = shapeById(PieceShapeId.single);
      final tray = [TrayPiece(shape: shape)];
      final placedAt = <GridPosition>[];

      await tester.pumpWidget(
        realHarness(
          container(),
          BoardGrid(
            board: board,
            tray: tray,
            onPlace: (_, anchor) => placedAt.add(anchor),
          ),
          tray,
          board,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final source = tester.getCenter(find.byType(Draggable<int>));
      final dragTargetRect = tester.getRect(
        find.byType(DragTarget<int>).first,
      );
      // Comfortably past the maximum any legitimate "still reaching for
      // the board" pointer position could ever need (liftPixels +
      // feedbackHeight for a single-cell piece here is ~112px) — well
      // inside where the extra-reach strip still geometrically extends
      // to (it reaches all the way to the bottom of the screen), so this
      // specifically exercises "the strip caught the event, but the piece
      // itself had already left the board."
      final pointerTarget = Offset(
        dragTargetRect.left + dragTargetRect.width / 2,
        dragTargetRect.bottom + 200,
      );

      final gesture = await tester.startGesture(source);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(pointerTarget);
      await tester.pump(const Duration(milliseconds: 50));

      // No ghost preview should be showing anywhere on the board while
      // hovering this far past it.
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              (widget.decoration as BoxDecoration?)?.color ==
                  GamePalette.previewValid,
        ),
        findsNothing,
      );

      await gesture.up();
      await tester.pump(const Duration(seconds: 1));

      expect(placedAt, isEmpty);
    });
  });

  group('enableParticles', () {
    testWidgets(
        'defaults to true, rendering a Newton particle overlay for the '
        'real game', (tester) async {
      final board = boardFromRows(List.filled(10, '.' * 10));
      final tray = [TrayPiece(shape: shapeById(PieceShapeId.single))];

      await tester.pumpWidget(
        harness(
          boardGrid: BoardGrid(board: board, tray: tray, onPlace: (_, _) {}),
        ),
      );
      await tester.pump();

      expect(find.byType(Newton), findsOneWidget);
    });

    testWidgets(
        'false renders the grid with no Newton overlay at all — the '
        'tutorial passes this (user report: freezes/stutters during its '
        "step transitions) so Newton's own always-running Ticker never "
        'exists in that screen in the first place, rather than trying to '
        'tune an effect the tutorial never actually needed', (tester) async {
      final board = boardFromRows(List.filled(10, '.' * 10));
      final tray = [TrayPiece(shape: shapeById(PieceShapeId.single))];

      await tester.pumpWidget(
        harness(
          boardGrid: BoardGrid(
            board: board,
            tray: tray,
            onPlace: (_, _) {},
            enableParticles: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Newton), findsNothing);
    });
  });
}
