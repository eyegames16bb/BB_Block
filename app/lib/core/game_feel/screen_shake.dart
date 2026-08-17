import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Drives the Game Feel Engine's screen shake — a tiny event bus rather than
/// an animation itself: [shake] just records "something this strong just
/// happened" and bumps a generation counter; [ScreenShake] is the widget
/// that actually turns that into motion.
class ScreenShakeController extends ChangeNotifier {
  double magnitude = 0;
  int generation = 0;

  /// Requests a shake of the given [magnitude] (roughly logical pixels of
  /// peak displacement). Called repeatedly with different magnitudes is
  /// fine — each call is its own independent shake.
  void shake(double magnitude) {
    this.magnitude = magnitude;
    generation++;
    notifyListeners();
  }
}

/// Wraps [child] so every [ScreenShakeController.shake] call plays a short,
/// decaying wobble over it — the board area shivers on a heavy line clear
/// or frame break instead of nothing at all reacting to the impact.
class ScreenShake extends StatefulWidget {
  const ScreenShake({required this.controller, required this.child, super.key});

  final ScreenShakeController controller;
  final Widget child;

  @override
  State<ScreenShake> createState() => _ScreenShakeState();
}

class _ScreenShakeState extends State<ScreenShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    widget.controller.addListener(_onShake);
  }

  @override
  void didUpdateWidget(covariant ScreenShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onShake);
      widget.controller.addListener(_onShake);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onShake);
    _controller.dispose();
    super.dispose();
  }

  void _onShake() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // A decaying sine wobble: fast early oscillation that dies out by
        // t=1, scaled by how strong this particular shake was requested.
        final decay = (1 - t) * (1 - t);
        final magnitude = widget.controller.magnitude;
        final dx = math.sin(t * 42) * magnitude * decay;
        final dy = math.cos(t * 37) * magnitude * 0.6 * decay;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: widget.child,
    );
  }
}
