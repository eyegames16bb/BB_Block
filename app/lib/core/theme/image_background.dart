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
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(assetPath, fit: BoxFit.cover),
        ?child,
      ],
    );
  }
}
