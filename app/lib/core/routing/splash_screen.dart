import 'dart:async';

import 'package:bb_block/core/routing/startup_gate.dart';
import 'package:flutter/material.dart';

/// The very first thing shown on a cold app launch (user instruction) —
/// the EyeGames publisher logo, full-screen, for a fixed 3 seconds, before
/// handing off to [StartupGate] (which then decides tutorial-vs-home as it
/// already did). A plain internal state swap rather than a separate
/// `go_router` route: `AppRoutes.home` still resolves to exactly one
/// widget either way, and this keeps the splash a strictly *visual*
/// prelude with no navigation/route-history implications (no back-button
/// entry for it, nothing else changes about the app's routing).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _duration = Duration(seconds: 3);

  late final Timer _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_duration, () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const StartupGate();

    return const Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Image(
          image: AssetImage('assets/images/eyegames_logo.png'),
          // Fills the entire screen (user instruction: "ekranın tamamını
          // kaplayacak boyutta") — the source image was already prepared
          // at a phone-matching portrait aspect ratio, so `cover` shows it
          // essentially uncropped on most screens while still guaranteeing
          // full bleed on any aspect ratio.
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
