import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/app_localizations.dart';
import '../../../core/app_theme.dart';
import '../../providers/detection_provider.dart';
import '../../providers/farm_profile_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/settings_provider.dart';

/// Reconfigure the farm name, appearance (dark mode), the two
/// detection thresholds, and the app language. Every change is saved
/// to disk immediately (see SettingsProvider / LocaleProvider), so
/// nothing here is lost by backgrounding or closing the app.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _farmCtrl = TextEditingController(
      text: context.read<FarmProfileProvider>().profile?.name ?? '');

  @override
  void dispose() {
    _farmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final detection = context.read<DetectionProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Language ──────────────────────────────────────────────────
          Text(context.tr('settings_language'),
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink)),
          const SizedBox(height: 10),
          _LanguageSelector(
            current: localeProvider.locale,
            onChanged: (l) => localeProvider.setLocale(l),
          ),
          const SizedBox(height: 28),

          // ── Farm name ─────────────────────────────────────────────────
          Text(context.tr('settings_farm_label'),
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink)),
          const SizedBox(height: 8),
          TextField(
            controller: _farmCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: context.tr('settings_farm_hint'),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final name = _farmCtrl.text.trim();
                if (name.isEmpty) return;
                await context.read<FarmProfileProvider>().updateName(name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('settings_farm_saved'))));
                }
              },
              child: Text(context.tr('settings_farm_save')),
            ),
          ),
          const SizedBox(height: 28),

          // ── Appearance ────────────────────────────────────────────────
          Text(context.tr('settings_appearance'),
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow),
            child: SwitchListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              secondary: Icon(
                  settings.darkModeEnabled
                      ? LucideIcons.moon
                      : LucideIcons.sun,
                  size: 19,
                  color: AppColors.deepBlue),
              title: Text(context.tr('settings_dark_mode'),
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink)),
              subtitle: Text(context.tr('settings_dark_mode_desc'),
                  style: TextStyle(fontSize: 11.5, color: AppColors.slate)),
              value: settings.darkModeEnabled,
              activeThumbColor: AppColors.deepBlue,
              onChanged: (v) => settings.setDarkMode(v),
            ),
          ),
          const SizedBox(height: 28),

          // ── Detection thresholds ──────────────────────────────────────
          Text(context.tr('settings_thresholds'),
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(context.tr('settings_thresholds_desc'),
              style: TextStyle(
                  fontSize: 11.5, color: AppColors.slate, height: 1.5)),
          const SizedBox(height: 14),
          _slider(
            context.tr('settings_species_gate'),
            settings.verifierThreshold,
            (v) => settings.setVerifierThreshold(v),
          ),
          _slider(
            context.tr('settings_positive_threshold'),
            settings.operatingThreshold,
            (v) => settings.setOperatingThreshold(v),
          ),
          const SizedBox(height: 28),

          // ── Model status ──────────────────────────────────────────────
          Text(context.tr('settings_model_status'),
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink)),
          const SizedBox(height: 10),
          _ModelStatusTile(
            label: context.tr('settings_verifier'),
            checkingLabel: context.tr('settings_model_checking'),
            readyLabel: context.tr('settings_model_ready'),
            notReadyLabel: context.tr('settings_model_not_ready'),
            future: () => detection.checkVerifierReady(),
          ),
          const SizedBox(height: 8),
          _ModelStatusTile(
            label: context.tr('settings_detector'),
            checkingLabel: context.tr('settings_model_checking'),
            readyLabel: context.tr('settings_model_ready'),
            notReadyLabel: context.tr('settings_model_not_ready'),
            future: () => detection.checkDetectorReady(),
          ),
          const SizedBox(height: 28),

          // ── Stored data ───────────────────────────────────────────────
          Text(context.tr('settings_stored_data'),
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink)),
          const SizedBox(height: 10),
          _tile(context, LucideIcons.fileSpreadsheet,
              context.tr('settings_export_csv'), () => detection.exportCsv()),
        ],
      ),
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label,
                style: TextStyle(fontSize: 12.5, color: AppColors.ink)),
            Text('${(value * 100).round()}%',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepBlue)),
          ]),
          Slider(
            value: value,
            min: 0.10,
            max: 0.95,
            divisions: 17,
            activeColor: AppColors.deepBlue,
            onChanged: onChanged,
          ),
        ]),
      );

  Widget _tile(BuildContext c, IconData i, String t, VoidCallback onTap) =>
      Container(
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Icon(i, size: 19, color: AppColors.deepBlue),
          title: Text(t,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
          trailing: Icon(LucideIcons.chevronRight,
              size: 15, color: AppColors.slate),
          onTap: onTap,
        ),
      );
}

// ---------------------------------------------------------------------------
// Language selector widget
// ---------------------------------------------------------------------------

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.current, required this.onChanged});

  final AppLocale current;
  final ValueChanged<AppLocale> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow),
      child: Column(
        children: AppLocale.values.map((locale) {
          final isLast = locale == AppLocale.values.last;
          return Column(
            children: [
              InkWell(
                onTap: () => onChanged(locale),
                borderRadius: BorderRadius.vertical(
                  top: locale == AppLocale.values.first
                      ? const Radius.circular(16)
                      : Radius.zero,
                  bottom: isLast ? const Radius.circular(16) : Radius.zero,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Icon(
                        current == locale
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 20,
                        color: current == locale
                            ? AppColors.deepBlue
                            : AppColors.slate,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        locale.displayName,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: current == locale
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: current == locale
                              ? AppColors.deepBlue
                              : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(height: 1, indent: 48, color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Model status tile
// ---------------------------------------------------------------------------

class _ModelStatusTile extends StatelessWidget {
  const _ModelStatusTile({
    required this.label,
    required this.future,
    required this.checkingLabel,
    required this.readyLabel,
    required this.notReadyLabel,
  });

  final String label;
  final Future<bool> Function() future;
  final String checkingLabel;
  final String readyLabel;
  final String notReadyLabel;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: future(),
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final ok = snap.data ?? false;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.cardShadow),
          child: Row(children: [
            if (loading)
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(ok ? LucideIcons.circleCheck : LucideIcons.circleX,
                  size: 18, color: ok ? AppColors.mintDark : Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink)),
            ),
            Text(
              loading ? checkingLabel : (ok ? readyLabel : notReadyLabel),
              style: TextStyle(
                  fontSize: 11.5,
                  color: loading
                      ? AppColors.slate
                      : (ok ? AppColors.mintDark : Colors.redAccent)),
            ),
          ]),
        );
      },
    );
  }
}
