import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A procedurally painted wood-grain surface, standing in for a real wood
/// texture photo (none is bundled yet — see CLAUDE.md). Approximates the
/// reference mockups' mahogany background: a vertical light/dark falloff
/// plus faint wavy fiber striations, rather than a flat solid color.
class WoodBackground extends StatelessWidget {
  const WoodBackground({this.child, this.seed = 7, super.key});

  final Widget? child;

  /// Fixed so the grain pattern is stable across rebuilds instead of
  /// reshuffling every frame.
  final int seed;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _WoodGrainPainter(seed: seed),
        child: child ?? const SizedBox.expand(),
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  const _WoodGrainPainter({required this.seed});

  final int seed;

  static const _grainLineCount = 46;
  static const _base = [
    Color(0xFF20100A),
    Color(0xFF7A4128),
    Color(0xFF9C5A34),
    Color(0xFF6B3A22),
    Color(0xFF3A1D12),
  ];
  static const _baseStops = [0.0, 0.14, 0.24, 0.6, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _base,
          stops: _baseStops,
        ).createShader(rect),
    );

    final random = math.Random(seed);
    for (var i = 0; i < _grainLineCount; i++) {
      final x = random.nextDouble() * size.width;
      final sway = (random.nextDouble() - 0.5) * size.width * 0.06;
      final opacity = 0.03 + random.nextDouble() * 0.09;
      final lighter = random.nextBool();
      final width = 0.6 + random.nextDouble() * 1.8;

      final path = Path()..moveTo(x, 0);
      const segments = 5;
      for (var s = 1; s <= segments; s++) {
        final t = s / segments;
        path.lineTo(
          x + sway * math.sin(t * math.pi) + (random.nextDouble() - 0.5) * 10,
          size.height * t,
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = (lighter ? Colors.white : Colors.black)
              .withValues(alpha: opacity),
      );
    }

    // A soft vignette ties the edges together, echoing the mockups' framed,
    // slightly-darker corners.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.1,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.28)],
          stops: const [0.6, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _WoodGrainPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
