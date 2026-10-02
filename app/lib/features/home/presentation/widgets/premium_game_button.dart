import 'package:bb_block/core/game_feel/spring_pressable.dart';
import 'package:flutter/material.dart';

/// A glossy "jelly glass" pill button — no wood frame (user instruction:
/// removed it, "tahta çerçeve falan olmasın"). A single smooth
/// top-to-bottom gradient (bright highlight near the top fading to the
/// saturated color), a thin darker rim of the same hue, and a soft
/// colored glow underneath instead of a plain black drop shadow. Icon +
/// label are centered together as one group (user instruction: "yazılar
/// ortada olsun" — not left-aligned with the icon off to the side), with
/// a crisp, high-contrast double-shadow on the text (user instruction:
/// "yazıların keskinliği yüksek olsun").
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

  static const double _height = 60;
  static const double _radius = _height / 2;

  @override
  Widget build(BuildContext context) {
    return SpringPressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: _height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [glossTop, glossMid, glossDeep],
            stops: const [0, 0.55, 1],
          ),
          border: Border.all(color: glossDeep, width: 2),
          boxShadow: [
            // A soft shadow tinted with the pill's own color instead of a
            // plain black drop shadow.
            BoxShadow(
              color: glossMid.withValues(alpha: 0.55),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The broad glass highlight band near the top.
              Positioned(
                left: _height * 0.18,
                right: _height * 0.18,
                top: _height * 0.08,
                height: _height * 0.42,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_height),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: glossDeep, blurRadius: 1),
                      const Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Fredoka',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      shadows: [
                        Shadow(color: glossDeep, blurRadius: 1),
                        const Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 2),
                          blurRadius: 4,
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
    );
  }
}
