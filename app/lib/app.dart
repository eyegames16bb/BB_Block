import 'package:bb_block/core/routing/app_router.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BbBlockApp extends StatelessWidget {
  const BbBlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BB Block',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
