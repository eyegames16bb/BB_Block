import 'dart:ui';

import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:flutter/material.dart';

/// The shared "game panel" chrome — a walnut-gradient wood frame (the same
/// `woodMid`/`woodDeep` pairing `PremiumGameButton` uses) around a blurred,
/// warm wood-toned inner fill. Used for every modal card in the app (pause,
/// round-over, Gold Coin progress, booster sheets, rate-us, ad confirm) so
/// they all read as one consistent family of in-game wooden signs rather
/// than generic app dialogs (user instruction: "bütün menüler aynı
/// tasarımda olsun" — redesigned from the earlier flat navy glass card to
/// match the Settings screen's wood-plank language). The public API
/// (`child`/`padding`/`borderRadius`/`opacity`) is unchanged, so every call
/// site picked this up automatically with no changes of its own.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 22,
    this.opacity = 0.55,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double opacity;

  static const double _borderWidth = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_borderWidth),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.woodMid, AppColors.woodDeep],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - _borderWidth),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GamePalette.bezelLight.withValues(alpha: opacity),
                  GamePalette.bezelDark.withValues(alpha: opacity),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
