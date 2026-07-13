import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_theme.dart';

class _BioTip {
  const _BioTip({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

const _tips = [
  _BioTip(
    icon: LucideIcons.hand,
    title: 'Sanitize hands between ponds',
    body: 'Wash or sanitize before and after handling fish from a different enclosure.',
  ),
  _BioTip(
    icon: LucideIcons.package,
    title: 'Disinfect nets & equipment',
    body: 'Shared nets and basins are a common way disease travels between grow-out ponds.',
  ),
  _BioTip(
    icon: LucideIcons.smartphone,
    title: 'Keep your phone dry',
    body: 'Avoid direct device contact with pond water when capturing scans.',
  ),
  _BioTip(
    icon: LucideIcons.triangleAlert,
    title: 'Isolate suspected cases',
    body: 'Move a Presumptive Positive fish to a separate holding container while you seek verification.',
  ),
];

/// Reachable anytime from the tab bar rather than forced on launch —
/// reduces onboarding friction while staying available to farmers who
/// want it. See the UI/UX design philosophy.
class BiosecurityTipsScreen extends StatelessWidget {
  const BiosecurityTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 52, 22, 26),
            decoration: const BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 17),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Biosecurity Tips',
                      style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Simple habits that reduce the risk of spreading disease between ponds.',
                  style: TextStyle(color: Color(0xFFD7ECF2), fontSize: 12.5, height: 1.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: _tips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final tip = _tips[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.ice, borderRadius: BorderRadius.circular(12)),
                        child: Icon(tip.icon, size: 19, color: AppColors.deepBlue),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tip.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 3),
                            Text(tip.body, style: const TextStyle(fontSize: 11.5, color: Colors.black54, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
