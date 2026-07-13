import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/app_theme.dart';
import 'screens/biosecurity/biosecurity_tips_screen.dart';
import 'screens/capture/camera_capture_screen.dart';
import 'screens/history/detection_history_screen.dart';

/// Hosts the three tab-bar-reachable screens (Scan / History / Tips)
/// behind a persistent bottom navigation bar, per the UI Navigation
/// Map (Fig. 3-11 of the proposal).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    CameraCaptureScreen(),
    DetectionHistoryScreen(),
    BiosecurityTipsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                _NavItem(icon: LucideIcons.camera, label: 'Scan', active: _index == 0, onTap: () => setState(() => _index = 0)),
                _NavItem(icon: LucideIcons.history, label: 'History', active: _index == 1, onTap: () => setState(() => _index = 1)),
                _NavItem(icon: LucideIcons.shieldCheck, label: 'Tips', active: _index == 2, onTap: () => setState(() => _index = 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.deepBlue : AppColors.slate;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
