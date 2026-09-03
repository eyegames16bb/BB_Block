import 'package:bb_block/core/game_feel/spring_pressable.dart';
import 'package:bb_block/core/routing/app_router.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/core/theme/glass_panel.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// The "watch ad, earn +100 Coin" confirmation — a bottom sheet (user
/// instruction: moved down from a centered dialog, content unchanged) shared
/// between the home screen's "Ödüllü Reklam" chip and the in-game Coin
/// badge, both of which open the same rewarded-ad bridge on confirmation.
Future<void> confirmAndWatchAd(BuildContext context) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => const _WatchAdConfirmSheet(),
  );
  if (confirmed == true && context.mounted) {
    await context.push(AppRoutes.rewardedAd);
  }
}

class _WatchAdConfirmSheet extends StatelessWidget {
  const _WatchAdConfirmSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                PhosphorIconsFill.coin,
                color: GamePalette.recordGold,
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.watchAdConfirmMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.paper,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              SpringPressable(
                onTap: () => Navigator.of(context).pop(true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: GamePalette.recordGold,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: GamePalette.recordGold.withValues(alpha: 0.45),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Text(
                    l10n.watchAdConfirmButton,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
