import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../../core/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        Center(
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.teal, AppColors.deepBlue]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(LucideIcons.fish, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text('TilapiaVision',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text('Version 1.0.0 — offline build',
              style: TextStyle(fontSize: 12, color: AppColors.slate)),
        ),
        const SizedBox(height: 24),
        _card('What this app does',
            'TilapiaVision screens photographs of Nile Tilapia for visual '
            'signs consistent with Motile Aeromonas Septicemia (hemorrhagic '
            'lesions). Everything runs on-device — no internet, no account.'),
        _card('How it works',
            'Two models run in sequence. A species check first confirms the '
            'photo shows a tilapia; only then does the lesion detector run. '
            'That is why photographing something else returns "Not a '
            'Tilapia" rather than a disease result.'),
        _card('Important limitation',
            'This is a presumptive screening tool, not a veterinary '
            'diagnosis. It detects only visible external symptoms and '
            'cannot rule out internal or asymptomatic conditions. Always '
            'confirm with a qualified professional before treatment.'),
        _card('Your data',
            'Detection photos are deleted automatically after '
            '${DetectionConfig.imageRetentionDays} days. Detection records '
            'stay until you delete or export them. Nothing leaves your '
            'device unless you share it yourself.'),
      ]),
    );
  }

  Widget _card(String t, String b) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.navy)),
          const SizedBox(height: 6),
          Text(b,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.6, color: Colors.black54)),
        ]),
      );
}
