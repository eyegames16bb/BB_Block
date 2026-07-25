import 'package:flutter/material.dart' hide Velocity;
import 'package:newton_particles/newton_particles.dart';

/// A small burst of square wood-chip particles, standing in for a real dust
/// photo/texture (none is bundled yet — see CLAUDE.md). Mirrors
/// `ExplosionPreset.toConfiguration()`'s structure but swaps circles for
/// squares and fire colors for the board's own wood palette, and scales the
/// particle count/size/velocity down to board-cell-sized bursts instead of a
/// full-screen explosion.
PhysicsEffectConfiguration woodDustBurst({
  required Offset origin,
  required List<Color> colors,
  int particleCount = 10,
  double particleSize = 5,
  double maxVelocity = 14,
}) {
  return PhysicsEffectConfiguration(
    physicsProperties: PhysicsProperties(
      gravity: const Gravity(0, 30),
      angle: const NumRange.between(0, 360),
      velocity: NumRange.between(
        Velocity.custom(6),
        Velocity.custom(maxVelocity),
      ),
      solidEdges: SolidEdges.none,
    ),
    visualProperties: const VisualProperties(
      endScale: NumRange.between(0.1, 0.3),
      fadeOutThreshold: NumRange.between(0.4, 0.7),
      scaleCurve: Curves.easeOut,
      fadeOutCurve: Curves.easeIn,
    ),
    emissionProperties: EmissionProperties(
      particleCount: particleCount,
      particlesPerEmit: particleCount,
      emitDuration: const Duration(milliseconds: 1),
      origin: origin,
      particleLifespan: const DurationRange.single(Duration(milliseconds: 650)),
    ),
    particleConfiguration: ParticleConfiguration(
      shape: const SquareShape(),
      size: Size(particleSize, particleSize),
      color: LinearInterpolationParticleColor(colors: colors),
    ),
  );
}
