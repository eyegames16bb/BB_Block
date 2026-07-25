import 'package:bb_block/core/game_feel/spring_pressable.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The "premium casual game button" the user specced directly (walnut wood
/// outer frame, glossy 3-stop vertical gradient inner face, top gloss
/// highlight, dark bottom edge, spring press-and-bounce) — used for the two
/// home screen mode buttons. [SpringPressable] supplies the press physics;
/// this widget is purely the chrome + the 3-stop gloss gradient, which is
/// the one part that has to vary per instance (green for Level Mod, blue
/// for Classic Mod).
class PremiumGameButton extends StatelessWidget {
  const PremiumGameButton({
    required this.label,
    required this.icon,
    required this.glossTop,
    required this.glossMid,
    required this.glossDeep,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color glossTop;
  final Color glossMid;
  final Color glossDeep;
  final VoidCallback? onTap;

  static const double _height = 72;
  static const double _outerRadius = 22;
  static const double _borderWidth = 8;

  @override
  Widget build(BuildContext context) {
    return SpringPressable(
      onTap: onTap,
      child: Container(
        height: _height,
        padding: const EdgeInsets.all(_borderWidth),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.woodMid, AppColors.woodDeep],
          ),
          borderRadius: BorderRadius.circular(_outerRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [glossTop, glossMid, glossDeep],
              stops: const [0, 0.55, 1],
            ),
            borderRadius: BorderRadius.circular(_outerRadius - _borderWidth),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_outerRadius - _borderWidth),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Bottom inner shadow — Flutter has no native inset
                // box-shadow, so this fakes one with a dark gradient
                // hugging the bottom edge instead.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _height * 0.4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          glossDeep.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Top glossy reflection.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: _height * 0.45,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.32),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                      shadows: const [
                        Shadow(color: AppColors.ink, blurRadius: 3),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: AppColors.ink,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
