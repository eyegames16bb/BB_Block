import 'dart:ui';

import 'package:bb_block/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A frosted-glass card — blurred, semi-transparent, with a faint light
/// border and a soft drop shadow — used everywhere a panel needs to sit
/// on top of the game's busy wood/photo backgrounds without either being a
/// flat opaque block or fully see-through. Replaces the plain solid-navy
/// `Card`/`Container` panels (settings, pause, round-over, choice sheets)
/// that read as a placeholder-grade "basic" look.
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
