import 'dart:async';

import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/core/services/audio/sound_effect.dart';
import 'package:bb_block/core/services/haptics/haptics_service.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Game Feel Engine's core tactile primitive: every tappable wood/glossy
/// chrome button in the app (home screen mode buttons, in-game header/
/// booster buttons) presses through this, so pressing anything in BB Block
/// feels like one consistent physical object rather than a grab-bag of ad
/// hoc animations — and, per the GDD's "her butonun basış sesi olmalı"
/// (every button needs a press sound), every one of them gets the same
/// click + light haptic for free just by being built on this widget,
/// instead of each call site having to remember to wire it in itself.
///
/// Press-down is instantaneous (a real button doesn't ease into being
/// pressed), but release is driven by an actual [SpringSimulation] rather
/// than a canned easing curve — the same physically-modeled snap-back the
/// GDD's "Game Feel" spec asks for, deliberately allowed to overshoot past
/// rest for a soft bounce instead of being clamped to [0, 1].
class SpringPressable extends ConsumerStatefulWidget {
  const SpringPressable({
    required this.onTap,
    required this.child,
    this.pressedScale = 0.96,
    this.pressedTranslateY = 4,
    super.key,
  });

  final VoidCallback? onTap;
  final Widget child;

  /// Scale at full press (1.0 = no shrink).
  final double pressedScale;

  /// How far the button sinks downward at full press, in logical pixels.
  final double pressedTranslateY;

  @override
  ConsumerState<SpringPressable> createState() => _SpringPressableState();
}

class _SpringPressableState extends ConsumerState<SpringPressable>
    with SingleTickerProviderStateMixin {
  // Tuned for a quick settle with one visible soft overshoot within
  // ~180ms — a lower damping ratio bounces more but takes longer to
  // fully rest.
  static final _releaseSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 380,
    ratio: 0.45,
  );

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    if (widget.onTap == null) return;
    _controller
      ..stop()
      ..value = 1;
    unawaited(
      ref.read(audioServiceProvider).playEffect(SoundEffect.buttonClick),
    );
    unawaited(ref.read(hapticsServiceProvider).trigger(HapticIntensity.light));
  }

  void _release() {
    if (widget.onTap == null) return;
    _controller.animateWith(
      SpringSimulation(_releaseSpring, _controller.value, 0, -1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _press(),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Deliberately unclamped: the spring can swing slightly past 0
            // on release, which is what reads as a soft bounce rather than
            // a mechanical stop.
            final t = _controller.value;
            final scale = 1 - (1 - widget.pressedScale) * t;
            return Transform.translate(
              offset: Offset(0, widget.pressedTranslateY * t),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
