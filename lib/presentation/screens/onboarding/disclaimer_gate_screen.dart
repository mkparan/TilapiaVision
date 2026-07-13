import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_theme.dart';
import 'farm_profile_setup_screen.dart';

/// Mandatory click-through establishing TilapiaVision as a
/// presumptive triage tool — not a veterinary diagnosis — before any
/// camera access is granted. See Section 1.5 of the proposal and the
/// "Diagnostic Disclaimer Gate" principle in the UI/UX design
/// philosophy.
class DisclaimerGateScreen extends StatefulWidget {
  const DisclaimerGateScreen({super.key});

  @override
  State<DisclaimerGateScreen> createState() => _DisclaimerGateScreenState();
}

class _DisclaimerGateScreenState extends State<DisclaimerGateScreen> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.fish, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'TilapiaVision',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontSize: 26),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Offline hemorrhagic lesion screening for Nile Tilapia',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: AppColors.ice, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(LucideIcons.triangleAlert, size: 17, color: AppColors.teal),
                      ),
                      const SizedBox(width: 10),
                      Text('Before You Begin', style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'TilapiaVision screens for visual signs consistent with hemorrhagic disease. '
                    'It is a detection support tool — not a veterinary diagnosis. Always confirm '
                    'results with a qualified professional before treatment.',
                    style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.55),
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    onTap: () => setState(() => _acknowledged = !_acknowledged),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.ice, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acknowledged,
                            activeColor: AppColors.deepBlue,
                            onChanged: (v) => setState(() => _acknowledged = v ?? false),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                'I understand this is a presumptive screening tool, not a medical diagnosis.',
                                style: TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _acknowledged
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const FarmProfileSetupScreen()),
                              )
                          : null,
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
