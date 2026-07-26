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

/// The "Block Place" Game Feel sequence's spark burst — a handful of tiny,
/// bright golden sparks fired at the end of the placement sequence (after
/// the hit-freeze), matching the reference mockup's glowing-outline
/// placement sparkles. Deliberately smaller, brighter, and shorter-lived
/// than [woodDustBurst] (which is for breaking wood, not landing it).
PhysicsEffectConfiguration placementSparkle({required Offset origin}) {
  return PhysicsEffectConfiguration(
    physicsProperties: PhysicsProperties(
      gravity: const Gravity(0, 6),
      angle: const NumRange.between(0, 360),
      velocity: NumRange.between(Velocity.custom(4), Velocity.custom(10)),
      solidEdges: SolidEdges.none,
    ),
    visualProperties: const VisualProperties(
      endScale: NumRange.between(0.05, 0.2),
      fadeOutThreshold: NumRange.between(0.3, 0.6),
      scaleCurve: Curves.easeOut,
      fadeOutCurve: Curves.easeIn,
    ),
    emissionProperties: EmissionProperties(
      particleCount: 6,
      particlesPerEmit: 6,
      emitDuration: const Duration(milliseconds: 1),
      origin: origin,
      particleLifespan: const DurationRange.single(Duration(milliseconds: 380)),
    ),
    particleConfiguration: const ParticleConfiguration(
      shape: SquareShape(),
      size: Size(3, 3),
      color: LinearInterpolationParticleColor(
        colors: [Color(0xFFFFF2C8), Color(0xFFFFCB5C), Color(0xFFF2B93B)],
      ),
    ),
  );
}

/// Level Complete's confetti — a much bigger, longer-lived burst than
/// [woodDustBurst], scattering wide across the screen and falling for over
/// a second instead of a quick cell-sized puff, in the same wood/gold
/// palette as the rest of the game rather than a generic rainbow.
PhysicsEffectConfiguration confettiBurst({required Offset origin}) {
  return PhysicsEffectConfiguration(
    physicsProperties: PhysicsProperties(
      gravity: const Gravity(0, 45),
      angle: const NumRange.between(200, 340),
      velocity: NumRange.between(
        Velocity.custom(22),
        Velocity.custom(42),
      ),
      solidEdges: SolidEdges.none,
    ),
    visualProperties: const VisualProperties(
      endScale: NumRange.between(0.5, 1),
      fadeOutThreshold: NumRange.between(0.65, 0.9),
      scaleCurve: Curves.easeOut,
      fadeOutCurve: Curves.easeIn,
    ),
    emissionProperties: EmissionProperties(
      particleCount: 60,
      particlesPerEmit: 60,
      emitDuration: const Duration(milliseconds: 1),
      origin: origin,
      particleLifespan: const DurationRange.single(
        Duration(milliseconds: 1600),
      ),
    ),
    particleConfiguration: const ParticleConfiguration(
      shape: SquareShape(),
      size: Size(9, 9),
      color: LinearInterpolationParticleColor(
        colors: [
          Color(0xFFF2B93B),
          Color(0xFFFCE07E),
          Color(0xFFDCAA6C),
          Color(0xFFF7D297),
        ],
      ),
    ),
  );
}
