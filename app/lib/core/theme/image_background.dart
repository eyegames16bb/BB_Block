import 'package:flutter/widgets.dart';

/// A full-bleed background image — plain `BoxFit.cover`, no extra zoom or
/// crop tricks (see CLAUDE.md's home-screen background note on why
/// artificial zooming was deliberately dropped: it fights the "fits the
/// screen" look more than it helps).
class ImageBackground extends StatelessWidget {
  const ImageBackground({required this.assetPath, this.child, super.key});

  final String assetPath;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // Decodes to the actual screen resolution instead of the source PNG's
    // full native size — same crop/fit, just a cheaper decode. Safe because
    // this widget always fills the screen (`StackFit.expand`), so the
    // screen's own physical size is exactly the target render size.
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          cacheWidth: (size.width * dpr).round(),
          cacheHeight: (size.height * dpr).round(),
        ),
        ?child,
      ],
    );
  }
}
