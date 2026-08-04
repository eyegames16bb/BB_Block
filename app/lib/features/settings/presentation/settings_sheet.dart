import 'dart:async';

import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/providers/url_launcher_providers.dart';
import 'package:bb_block/core/routing/app_router.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/core/theme/glass_panel.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:bb_block/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Shown from the gear icon on both the main menu and the game screen.
class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      // The sheet's content has grown (credits, language toggle, and
      // eventually the tutorial replay row) — scroll-controlled + an inner
      // SingleChildScrollView keeps it from overflowing on short screens
      // instead of silently clipping.
      isScrollControlled: true,
      builder: (context) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progress =
        ref.watch(playerProgressControllerProvider).value ??
        const PlayerProgress();
    final controller = ref.read(playerProgressControllerProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: GlassPanel(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        PhosphorIconsBold.gear,
                        color: AppColors.paper,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.settingsTitle,
                        style:
                            Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: AppColors.paper,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SettingToggle(
                    icon: PhosphorIconsBold.speakerHigh,
                    label: l10n.soundLabel,
                    value: progress.soundEnabled,
                    onChanged: (enabled) =>
                        controller.setSoundEnabled(enabled: enabled),
                  ),
                  const SizedBox(height: 10),
                  _LanguageRow(
                    label: l10n.languageLabel,
                    languageCode: progress.languageCode,
                    onChanged: controller.setLanguageCode,
                  ),
                  const SizedBox(height: 10),
                  _ReplayTutorialRow(label: l10n.replayTutorialLabel),
                  const SizedBox(height: 18),
                  Text(
                    l10n.aboutSectionTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.paper),
                  ),
                  const SizedBox(height: 10),
                  // The developer (HAYB) credit row was removed here (user
                  // instruction) — only the publisher credit remains below.
                  _CreditLink(
                    label: l10n.publisherCreditLabel,
                    value: CreditsConstants.publisherName,
                    url: CreditsConstants.publisherUrl,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable "label: value" row that opens [url] externally — the
/// developer/publisher credits (user instruction).
class _CreditLink extends ConsumerWidget {
  const _CreditLink({
    required this.label,
    required this.value,
    required this.url,
  });

  final String label;
  final String value;
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => ref.read(urlLauncherServiceProvider).launch(url),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                PhosphorIconsBold.arrowSquareOut,
                color: AppColors.paper.withValues(alpha: 0.55),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.paper.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: GamePalette.recordGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Replays the first-launch interactive tutorial on demand (user
/// instruction — re-added after an earlier removal in this same session, so
/// the user can re-test it without needing a fresh install each time).
/// Closes this sheet first — the tutorial is a full-screen experience, not
/// something to layer a modal on top of.
class _ReplayTutorialRow extends StatelessWidget {
  const _ReplayTutorialRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).pop();
        unawaited(context.push(AppRoutes.tutorial));
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              Icon(
                PhosphorIconsBold.playCircle,
                color: AppColors.paper.withValues(alpha: 0.55),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.paper,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

class _SettingToggle extends StatelessWidget {
  const _SettingToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Icon(
              icon,
              color: value
                  ? GamePalette.recordGold
                  : AppColors.paper.withValues(alpha: 0.55),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.paper,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: GamePalette.recordGold,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// A two-way TR/EN segmented control — user instruction: full language
/// support, switchable from Settings. `languageCode` drives `BbBlockApp`'s
/// `locale` directly (see app.dart), so a change here retranslates the
/// whole app immediately.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.languageCode,
    required this.onChanged,
  });

  final String label;
  final String languageCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Icon(
              PhosphorIconsBold.globe,
              color: AppColors.paper.withValues(alpha: 0.55),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.paper,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _LanguageOption(
              code: 'tr',
              label: 'TR',
              selected: languageCode == 'tr',
              onTap: () => onChanged('tr'),
            ),
            const SizedBox(width: 6),
            _LanguageOption(
              code: 'en',
              label: 'EN',
              selected: languageCode == 'en',
              onTap: () => onChanged('en'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? GamePalette.recordGold
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.ink : AppColors.paper,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
