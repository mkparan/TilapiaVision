import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_localizations.dart';
import '../../../core/app_theme.dart';
import '../settings/about_screen.dart';
import '../settings/settings_screen.dart';

/// Reachable anytime from the tab bar rather than forced on launch —
/// reduces onboarding friction while staying available to farmers who
/// want it. See the UI/UX design philosophy.
class BiosecurityTipsScreen extends StatelessWidget {
  const BiosecurityTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pre-capture translated labels from the widget-tree context.
    // PopupMenuButton's itemBuilder receives an overlay context that is
    // outside the Provider tree, so context.tr() would fail inside it.
    final menuSettings = context.tr('camera_menu_settings');
    final menuAbout = context.tr('camera_menu_about');

    // Tips are resolved at build time so they respond to language changes.
    final tips = [
      _BioTip(
        icon: LucideIcons.hand,
        title: context.tr('bio_tip1_title'),
        body: context.tr('bio_tip1_body'),
      ),
      _BioTip(
        icon: LucideIcons.package,
        title: context.tr('bio_tip2_title'),
        body: context.tr('bio_tip2_body'),
      ),
      _BioTip(
        icon: LucideIcons.smartphone,
        title: context.tr('bio_tip3_title'),
        body: context.tr('bio_tip3_body'),
      ),
      _BioTip(
        icon: LucideIcons.triangleAlert,
        title: context.tr('bio_tip4_title'),
        body: context.tr('bio_tip4_body'),
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 52, 22, 26),
            decoration: const BoxDecoration(
              // Fixed brand teal header — deliberately unchanged in
              // dark mode, matching the other tab headers.
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
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.shieldCheck,
                          color: Colors.white, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('bio_title'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(LucideIcons.ellipsisVertical,
                          color: Colors.white),
                      tooltip: 'More',
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onSelected: (v) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => v == 'settings'
                              ? const SettingsScreen()
                              : const AboutScreen(),
                        ));
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(children: [
                            Icon(LucideIcons.settings,
                                size: 17, color: AppColors.ink),
                            const SizedBox(width: 10),
                            Text(menuSettings),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'about',
                          child: Row(children: [
                            Icon(LucideIcons.info,
                                size: 17, color: AppColors.ink),
                            const SizedBox(width: 10),
                            Text(menuAbout),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('bio_subtitle'),
                  style: const TextStyle(
                      color: Color(0xFFD7ECF2), fontSize: 12.5, height: 1.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: tips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final tip = tips[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: AppColors.ice,
                            borderRadius: BorderRadius.circular(12)),
                        child:
                            Icon(tip.icon, size: 19, color: AppColors.deepBlue),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tip.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.ink)),
                            const SizedBox(height: 3),
                            Text(tip.body,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.slate,
                                    height: 1.5)),
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

class _BioTip {
  const _BioTip({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}
