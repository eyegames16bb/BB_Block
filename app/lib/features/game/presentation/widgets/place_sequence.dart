import 'dart:async';

import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/wood_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// The "Block Place" Game Feel sequence: one chained timeline instead of
/// independent effects firing all at once —
///
/// Place (spring pop) → Glow → *(haptic + wood-hit sound already fired by
/// `GameController` the instant the state changed, so they land right at
/// the pop's impact)* → Hit Freeze (50ms hold) → Sparkle particles →
/// Shadow expand.
///
/// Every stage after the initial spring pop is sequenced explicitly via
/// `async`/`await` rather than derived from one shared progress value, so
/// the 50ms freeze (user instruction: "kısa hit freeze (40-60ms)") is a
/// real hold (nothing animates) rather than an eased-out tail pretending
/// to be one.
class PlaceSequence extends StatefulWidget {
  const PlaceSequence({
    required this.cellSize,
    required this.onSparkle,
    super.key,
  });

  final double cellSize;

  /// Fired once, right after the hit-freeze — the caller is responsible for
  /// the actual particle burst (it needs the board's shared `Newton`
  /// overlay, which this widget has no access to).
  final VoidCallback onSparkle;

  @override
  State<PlaceSequence> createState() => _PlaceSequenceState();
}

class _PlaceSequenceState extends State<PlaceSequence>
    with TickerProviderStateMixin {
  // Underdamped on purpose — the overshoot-then-settle IS the "juice".
  static final _placeSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
    ratio: 0.6,
  );

  late final AnimationController _pop = AnimationController.unbounded(
    vsync: this,
    value: 0.72,
  );
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  late final AnimationController _shadow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    // Place + Glow start together.
    unawaited(_glow.forward());
    await _pop.animateWith(SpringSimulation(_placeSpring, 0.72, 1, 8));
    if (!mounted) return;

    // Hit Freeze — a real hold, not an eased tail. 50ms (user instruction:
    // "kısa hit freeze (40-60ms)" for placement specifically).
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    widget.onSparkle();
    await _shadow.forward();
    if (!mounted) return;
    await _shadow.reverse();
  }

  @override
  void dispose() {
    _pop.dispose();
    _glow.dispose();
    _shadow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pop, _glow, _shadow]),
      builder: (context, child) {
        final popValue = _pop.value;
        final opacity = ((popValue - 0.6) / 0.4).clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (_shadow.value > 0)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      widget.cellSize * 0.16,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GamePalette.recordGold.withValues(
                          alpha: 0.4 * _shadow.value,
                        ),
                        blurRadius: 4 + 16 * _shadow.value,
                        spreadRadius: 4 * _shadow.value,
                      ),
                    ],
                  ),
                ),
              ),
            if (_glow.value < 1)
              IgnorePointer(
                child: Opacity(
                  opacity: (1 - _glow.value).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.5 + 1.6 * _glow.value,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xE6FFFFFF),
                            Color(0x8CF2B93B),
                            Color(0x00F2B93B),
                          ],
                          stops: [0, 0.45, 1],
                        ),
                      ),
                      child: SizedBox(
                        width: widget.cellSize,
                        height: widget.cellSize,
                      ),
                    ),
                  ),
                ),
              ),
            Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: popValue.clamp(0.0, 1.6),
                child: child,
              ),
            ),
          ],
        );
      },
      child: WoodTile(size: widget.cellSize),
    );
  }
}
