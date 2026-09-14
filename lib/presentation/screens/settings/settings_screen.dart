import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../providers/detection_provider.dart';
import '../../providers/farm_profile_provider.dart';
import '../../providers/settings_provider.dart';

/// Reconfigure the farm name and the two detection thresholds.
/// Every change is saved to disk immediately (see SettingsProvider),
/// so nothing here is lost by backgrounding or closing the app.
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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Farm / Owner Name',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink)),
          const SizedBox(height: 8),
          TextField(
            controller: _farmCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Farm name',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final name = _farmCtrl.text.trim();
                if (name.isEmpty) return;
                await context
                    .read<FarmProfileProvider>()
                    .updateName(name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Farm name saved')));
                }
              },
              child: const Text('Save Farm Name'),
            ),
          ),
          const SizedBox(height: 28),
          const Text('Detection Thresholds',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink)),
          const SizedBox(height: 4),
          const Text(
              'Lower values flag more cases but risk more false '
              'positives. The species check is set high by default to '
              'avoid accepting random objects or misframed photos.',
              style: TextStyle(fontSize: 11.5, color: AppColors.slate, height: 1.5)),
          const SizedBox(height: 14),
          _slider(
            'Species check (Tilapia gate)',
            settings.verifierThreshold,
            (v) => settings.setVerifierThreshold(v),
          ),
          _slider(
            'Positive result threshold',
            settings.operatingThreshold,
            (v) => settings.setOperatingThreshold(v),
          ),
          const SizedBox(height: 28),
          const Text('Model Status',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink)),
          const SizedBox(height: 10),
          _ModelStatusTile(
            label: 'Species verifier',
            future: () => detection.checkVerifierReady(),
          ),
          const SizedBox(height: 8),
          _ModelStatusTile(
            label: 'Disease detector',
            future: () => detection.checkDetectorReady(),
          ),
          const SizedBox(height: 28),
          const Text('Stored Data',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink)),
          const SizedBox(height: 10),
          _tile(context, LucideIcons.fileSpreadsheet,
              'Export detection log (CSV)', () => detection.exportCsv()),
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
                style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Icon(i, size: 19, color: AppColors.deepBlue),
          title:
              Text(t, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          trailing:
              const Icon(LucideIcons.chevronRight, size: 15, color: AppColors.slate),
          onTap: onTap,
        ),
      );
}

class _ModelStatusTile extends StatelessWidget {
  const _ModelStatusTile({required this.label, required this.future});
  final String label;
  final Future<bool> Function() future;

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
              color: Colors.white,
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
                  size: 18,
                  color: ok ? AppColors.mintDark : Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Text(
              loading ? 'Checking…' : (ok ? 'Ready' : 'Not ready'),
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
