import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/app_localizations.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../core/tap_sequence.dart';
import '../../providers/locale_provider.dart';
import '../../providers/settings_provider.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  /// Tapping the logo this many times in quick succession unlocks the
  /// developer options in Settings (the two threshold sliders). The
  /// first few taps show nothing, so the feature stays out of sight of
  /// a casual tapper; only the last few taps show a countdown.
  final TapSequence _logoTaps = TapSequence(length: 7);
  static const _hintFromRemaining = 3;

  /// Runs from a tap, not from build(), so it must not call
  /// `context.tr` (that helper uses `context.watch`, which Provider only
  /// allows during build). The language is read once without watching.
  void _onLogoTap() {
    // A small tick on every tap, so even the early taps (which show no
    // message on purpose) are felt to register.
    HapticFeedback.selectionClick();

    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppLocalizations(context.read<LocaleProvider>().locale);

    final remaining = _logoTaps.tap(DateTime.now());

    String? message;
    if (remaining == 0) {
      if (settings.developerOptionsEnabled) {
        message = strings.tr('dev_already');
      } else {
        settings.setDeveloperOptionsEnabled(true);
        message = strings.tr('dev_unlocked');
      }
    } else if (remaining <= _hintFromRemaining &&
        !settings.developerOptionsEnabled) {
      message = strings.tr('dev_tap_progress').replaceAll('{n}', '$remaining');
    }

    if (message != null) {
      // clearSnackBars (not just hideCurrentSnackBar) so rapid taps
      // replace the message instead of queueing a backlog behind it.
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1500),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('about_title'))),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        // The whole header block (logo, name, version) is the tap zone
        // for unlocking developer options — a much bigger, more
        // forgiving target than the 66 px logo alone.
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onLogoTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/tilapiavision_logo.png',
                      width: 66,
                      height: 66,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('TilapiaVision',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.heading)),
                  const SizedBox(height: 4),
                  Text(context.tr('about_version'),
                      style: TextStyle(fontSize: 12, color: AppColors.slate)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _card(context, 'about_card1_title', 'about_card1_body'),
        _card(context, 'about_scope_title', 'about_scope_body'),
        _card(context, 'about_card2_title', 'about_card2_body'),
        _card(context, 'about_card3_title', 'about_card3_body'),
        _cardFmt(context, 'about_card4_title', 'about_card4_body',
            {'days': '${DetectionConfig.imageRetentionDays}'}),
      ]),
    );
  }

  Widget _card(BuildContext ctx, String titleKey, String bodyKey) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ctx.tr(titleKey),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: AppColors.heading)),
          const SizedBox(height: 6),
          Text(ctx.tr(bodyKey),
              style: TextStyle(
                  fontSize: 12.5, height: 1.6, color: AppColors.slate)),
        ]),
      );

  Widget _cardFmt(BuildContext ctx, String titleKey, String bodyKey,
          Map<String, String> args) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ctx.tr(titleKey),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: AppColors.heading)),
          const SizedBox(height: 6),
          Text(ctx.trFmt(bodyKey, args),
              style: TextStyle(
                  fontSize: 12.5, height: 1.6, color: AppColors.slate)),
        ]),
      );
}
