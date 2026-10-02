import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/game_feel/spring_pressable.dart';
import 'package:bb_block/core/providers/url_launcher_providers.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:bb_block/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Shown from the gear icon on both the main menu and the game screen.
///
/// Redesigned (user instruction) from a generic frosted-glass settings
/// panel into a wood-plank game menu that belongs to BB Block's own world —
/// the same walnut-frame/gloss-bevel chrome `PremiumGameButton` and the
/// in-game HUD (`GamePalette`'s wood tokens) already use, reused here
/// rather than inventing a new visual language or copying any reference
/// pixel-for-pixel. No new image assets — every bevel/gloss/shadow below is
/// drawn with gradients and box-shadows, the same technique the home
/// screen's mode buttons use. Every row's underlying function (what it
/// reads from/writes to `PlayerProgress`) is unchanged — this file only
/// changes how each row is drawn.
class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({this.showBoardSizeOption = true, super.key});

  // The Classic Mode board-size row (user instruction) only belongs on the
  // main menu's copy of this sheet — mid-round (Classic or Level, from the
  // in-game gear icon) it's hidden, since changing it wouldn't apply to the
  // round already in progress anyway.
  final bool showBoardSizeOption;

  static Future<void> show(
    BuildContext context, {
    bool showBoardSizeOption = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      // The sheet's content has grown (credits, language toggle, and
      // eventually the tutorial replay row) — scroll-controlled + an inner
      // SingleChildScrollView keeps it from overflowing on short screens
      // instead of silently clipping.
      isScrollControlled: true,
      builder: (context) =>
          SettingsSheet(showBoardSizeOption: showBoardSizeOption),
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
          child: _WoodPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WoodPanelHeader(
                  title: l10n.settingsTitle,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WoodToggleRow(
                          icon: PhosphorIconsBold.speakerHigh,
                          label: l10n.soundLabel,
                          value: progress.soundEnabled,
                          onChanged: (enabled) =>
                              controller.setSoundEnabled(enabled: enabled),
                        ),
                        if (showBoardSizeOption) ...[
                          const SizedBox(height: 10),
                          _ClassicBoardSizeRow(
                            label: l10n.classicBoardSizeLabel,
                            hasFrame: progress.classicHasFrame,
                            onChanged: (hasFrame) => controller
                                .setClassicHasFrame(hasFrame: hasFrame),
                          ),
                        ],
                        const SizedBox(height: 10),
                        _LanguageRow(
                          label: l10n.languageLabel,
                          languageCode: progress.languageCode,
                          onChanged: controller.setLanguageCode,
                        ),
                        const SizedBox(height: 10),
                        _WoodToggleRow(
                          icon: PhosphorIconsBold.info,
                          label: l10n.modeNotesLabel,
                          value: progress.showModeNotesEnabled,
                          onChanged: (enabled) => controller
                              .setShowModeNotesEnabled(enabled: enabled),
                        ),
                        const SizedBox(height: 18),
                        _ScoreboardSection(progress: progress),
                        const SizedBox(height: 18),
                        _WoodSectionLabel(text: l10n.aboutSectionTitle),
                        const SizedBox(height: 10),
                        // The developer (HAYB) credit row was removed here
                        // (user instruction) — only the publisher credit
                        // remains below.
                        _CreditLink(
                          label: l10n.publisherCreditLabel,
                          value: CreditsConstants.publisherName,
                          url: CreditsConstants.publisherUrl,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet's outer wood plank — a thick walnut-gradient frame (same
/// `woodMid`/`woodDeep` pairing `PremiumGameButton` uses for its own
/// border) around a warmer, deeper inner panel, so the whole sheet reads as
/// one carved wooden board rather than a translucent app card.
class _WoodPanel extends StatelessWidget {
  const _WoodPanel({required this.child});

  final Widget child;

  static const double _outerRadius = 26;
  static const double _borderWidth = 6;

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
        borderRadius: BorderRadius.circular(_outerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GamePalette.bezelLight, GamePalette.bezelDark],
          ),
          borderRadius: BorderRadius.circular(_outerRadius - _borderWidth),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_outerRadius - _borderWidth),
          child: child,
        ),
      ),
    );
  }
}

/// The plank-sign title bar — a darker wood strip (matching the booster/
/// piece-tray panel tone) with the gear icon, the title, and a round wood
/// close button in the corner (user instruction's reference had a close
/// affordance; this is a pure addition — it still just pops the sheet,
/// exactly like swiping it down already does).
class _WoodPanelHeader extends StatelessWidget {
  const _WoodPanelHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GamePalette.panelDark.withValues(alpha: 0.9),
            GamePalette.panelDark.withValues(alpha: 0.65),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GamePalette.woodButtonLight,
                  GamePalette.woodButtonDark,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GamePalette.woodButtonBorder),
            ),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                PhosphorIconsFill.gearSix,
                color: GamePalette.recordGold,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.paper,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
          SpringPressable(
            onTap: onClose,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    GamePalette.woodButtonLight,
                    GamePalette.woodButtonDark,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: GamePalette.woodButtonBorder),
                boxShadow: const [
                  BoxShadow(
                    color: GamePalette.buttonLedge,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                PhosphorIconsBold.x,
                color: AppColors.paper,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section label carved into a small wood tag instead of plain
/// `Theme.of(context).textTheme` text — used for "Hakkında".
class _WoodSectionLabel extends StatelessWidget {
  const _WoodSectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: GamePalette.recordGold,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.4,
        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
      ),
    );
  }
}

/// The shared chrome every settings row sits inside — the same dark-brown
/// panel + solid drop "ledge" shadow family as the in-game booster pills
/// and `_RoundIconButton` (`GamePalette.panelDark`/`buttonLedge`), instead
/// of the previous generic `Colors.white.withValues(alpha: 0.06)` card.
class _WoodRowShell extends StatelessWidget {
  const _WoodRowShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GamePalette.panelDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GamePalette.panelDarkBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(color: GamePalette.buttonLedge, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: child,
      ),
    );
  }
}

/// A small wood-chip icon badge — the left-hand icon on every row, carved
/// out of the same wood-button gradient the header's gear icon uses,
/// instead of a bare `Icon` floating on the row.
class _RowIconChip extends StatelessWidget {
  const _RowIconChip({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: active
              ? const [
                  GamePalette.woodButtonLight,
                  GamePalette.woodButtonDark,
                ]
              : [
                  GamePalette.woodButtonLight.withValues(alpha: 0.4),
                  GamePalette.woodButtonDark.withValues(alpha: 0.4),
                ],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: GamePalette.woodButtonBorder.withValues(
            alpha: active ? 1 : 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(
          icon,
          color: active
              ? GamePalette.recordGold
              : AppColors.paper.withValues(alpha: 0.5),
          size: 17,
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
    return SpringPressable(
      onTap: () => ref.read(urlLauncherServiceProvider).launch(url),
      child: _WoodRowShell(
        child: Row(
          children: [
            const _RowIconChip(
              icon: PhosphorIconsBold.arrowSquareOut,
              active: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.paper.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: GamePalette.recordGold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Classic Mode high-score row — moved here from the home screen (user
/// instruction) so removing the home screen's own scoreboard doesn't lose
/// the information. Only the two Classic Mode variants (8x8/10x10) show —
/// the Level counter stays off this panel per instruction ("Level sayısı
/// gözükmesin"). Restyled as a carved wood trophy plank instead of a plain
/// translucent card.
class _ScoreboardSection extends StatelessWidget {
  const _ScoreboardSection({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GamePalette.woodButtonLight, GamePalette.woodButtonDark],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GamePalette.woodButtonBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(color: GamePalette.buttonLedge, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ScoreStat(
              value: '${progress.classicHighScoreFramed}',
              label: l10n.statFramed,
            ),
          ),
          Container(
            width: 2,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: _ScoreStat(
              value: '${progress.classicHighScoreFrameless}',
              label: l10n.statFrameless,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  const _ScoreStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          PhosphorIconsFill.crown,
          color: GamePalette.recordGold,
          size: 18,
          shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.paper,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.paper.withValues(alpha: 0.75),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// An on/off setting drawn as a carved wood toggle pill (track + sliding
/// wood-gradient thumb) instead of Flutter's generic Material `Switch` —
/// the track glows gold when on, matches the dim wood-chip icon treatment
/// when off. Tapping anywhere on the row toggles it, same as before.
class _WoodToggleRow extends StatelessWidget {
  const _WoodToggleRow({
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
    return SpringPressable(
      onTap: () => onChanged(!value),
      child: _WoodRowShell(
        child: Row(
          children: [
            _RowIconChip(icon: icon, active: value),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.paper,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _WoodTogglePill(value: value),
          ],
        ),
      ),
    );
  }
}

class _WoodTogglePill extends StatelessWidget {
  const _WoodTogglePill({required this.value});

  final bool value;

  static const double _width = 46;
  static const double _height = 26;
  static const double _thumbSize = 20;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: _width,
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: value
              ? const [GamePalette.progressFillLight, GamePalette.recordGold]
              : [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.25),
                ],
        ),
        borderRadius: BorderRadius.circular(_height / 2),
        border: Border.all(
          color: value
              ? GamePalette.recordGold.withValues(alpha: 0.8)
              : GamePalette.panelDarkBorder,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: GamePalette.recordGold.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: _thumbSize,
          height: _thumbSize,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.paper, Color(0xFFD9CBB0)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black38, blurRadius: 3),
            ],
          ),
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
    return _SegmentedSettingRow(
      icon: PhosphorIconsBold.globe,
      label: label,
      children: [
        _SegmentOption(
          label: 'TR',
          selected: languageCode == 'tr',
          onTap: () => onChanged('tr'),
        ),
        const SizedBox(width: 6),
        _SegmentOption(
          label: 'EN',
          selected: languageCode == 'en',
          onTap: () => onChanged('en'),
        ),
      ],
    );
  }
}

/// Classic Mode's board size (8x8 framed / 10x10 frameless) — moved here
/// from an every-launch home screen sheet (user instruction), styled to
/// match `_LanguageRow` exactly ("Dil Seçimi" ayarına benzer ux). Defaults
/// to 8x8 (`PlayerProgress.classicHasFrame`'s own default), and the prominent
/// gold fill on the selected option is the same "belirgin sarı" treatment
/// the language toggle already used.
class _ClassicBoardSizeRow extends StatelessWidget {
  const _ClassicBoardSizeRow({
    required this.label,
    required this.hasFrame,
    required this.onChanged,
  });

  final String label;
  final bool hasFrame;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SegmentedSettingRow(
      icon: PhosphorIconsBold.gridFour,
      label: label,
      children: [
        _SegmentOption(
          label: l10n.classicBoardSize8x8,
          selected: hasFrame,
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 6),
        _SegmentOption(
          label: l10n.classicBoardSize10x10,
          selected: !hasFrame,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

/// Shared "icon + label + trailing segmented options" row shell used by both
/// [_LanguageRow] and [_ClassicBoardSizeRow] — now on the same wood-panel
/// chrome every other row uses.
class _SegmentedSettingRow extends StatelessWidget {
  const _SegmentedSettingRow({
    required this.icon,
    required this.label,
    required this.children,
  });

  final IconData icon;
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _WoodRowShell(
      child: Row(
        children: [
          _RowIconChip(icon: icon, active: true),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.paper,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SegmentOption extends StatelessWidget {
  const _SegmentOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpringPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    GamePalette.progressFillLight,
                    GamePalette.recordGold,
                  ],
                )
              : null,
          color: selected ? null : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? GamePalette.recordGold.withValues(alpha: 0.8)
                : GamePalette.panelDarkBorder,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: GamePalette.recordGold.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ]
              : null,
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
