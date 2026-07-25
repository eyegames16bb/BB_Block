import 'package:flutter/widgets.dart';

/// Wraps a wood-chrome button so it shrinks slightly on press and springs
/// back on release/cancel — the tactile "3D button" feedback the reference
/// mockups imply with their solid drop-shadow ledges, which a plain tap
/// ripple doesn't convey. Purely presentational: the actual tap is still
/// reported through [onTap], including when [onTap] is null (an
/// inert/disabled button just doesn't animate or fire).
class PressableScale extends StatefulWidget {
  const PressableScale({required this.onTap, required this.child, super.key});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
