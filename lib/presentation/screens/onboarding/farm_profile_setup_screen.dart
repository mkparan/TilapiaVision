import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../app_shell.dart';
import '../../providers/farm_profile_provider.dart';

/// No-Login Architecture: a local Farm Profile replaces passwords or
/// cloud accounts, so a farmer gets instant access even in an
/// emergency. See the UI/UX design philosophy for the rationale.
class FarmProfileSetupScreen extends StatefulWidget {
  const FarmProfileSetupScreen({super.key});

  @override
  State<FarmProfileSetupScreen> createState() => _FarmProfileSetupScreenState();
}

class _FarmProfileSetupScreenState extends State<FarmProfileSetupScreen> {
  final _nameController = TextEditingController();
  bool _acknowledged = false;
  bool _saving = false;

  bool get _canContinue => _nameController.text.trim().isNotEmpty && _acknowledged && !_saving;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    setState(() => _saving = true);
    final provider = context.read<FarmProfileProvider>();
    await provider.createProfile(_nameController.text.trim());
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set Up Your Farm Profile', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    const Text(
                      'No account or internet needed — everything stays on this device.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'FARM / OWNER NAME',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'e.g., Doongan Grow-Out Pond',
                        prefixIcon: Icon(LucideIcons.user, size: 19),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.ice, borderRadius: BorderRadius.circular(14)),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.info, size: 18, color: AppColors.teal),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Detection photos auto-delete after 30 days to save space. '
                              'Detection records stay in your local CSV log until you clear or export them.',
                              style: TextStyle(fontSize: 11.5, height: 1.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => setState(() => _acknowledged = !_acknowledged),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.ice, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _acknowledged,
                              activeColor: AppColors.deepBlue,
                              onChanged: (v) => setState(() => _acknowledged = v ?? false),
                            ),
                            const Expanded(
                              child: Text(
                                'I acknowledge the 30-day photo storage notice above.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: ElevatedButton(
                onPressed: _canContinue ? _createProfile : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Create Profile & Start Scanning'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
