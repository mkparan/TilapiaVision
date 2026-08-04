import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'data/repositories/detection_repository.dart';
import 'presentation/app_shell.dart';
import 'presentation/providers/detection_provider.dart';
import 'presentation/providers/farm_profile_provider.dart';
import 'presentation/screens/onboarding/disclaimer_gate_screen.dart';
import 'services/detection/mock_detection_engine.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget: clear any detection photos older than the
  // retention window (see DetectionConfig.imageRetentionDays). Runs
  // once per launch; a failure here shouldn't block app startup.
  unawaited(_clearExpiredImagesInBackground());
  runApp(const TilapiaVisionApp());
}

Future<void> _clearExpiredImagesInBackground() async {
  try {
    await StorageService().clearExpiredImages();
  } catch (_) {
    // Best-effort cleanup only.
  }
}

class TilapiaVisionApp extends StatelessWidget {
  const TilapiaVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FarmProfileProvider()..load()),
        ChangeNotifierProvider(
          create: (_) => DetectionProvider(
            // Swap MockDetectionEngine() -> TFLiteDetectionEngine() on
            // integration day — see
            // lib/services/detection/tflite_detection_engine.dart for
            // the full checklist. Nothing else in the app needs to
            // change.
            engine: MockDetectionEngine(),
            repository: DetectionRepository(),
            storageService: StorageService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'TilapiaVision',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _RootRouter(),
      ),
    );
  }
}

/// Decides which "page zero" to show: the mandatory onboarding flow
/// for first launch, or straight into the tab-bar app shell for a
/// returning user with a saved Farm Profile.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final farmProfileProvider = context.watch<FarmProfileProvider>();

    if (farmProfileProvider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!farmProfileProvider.hasProfile) {
      return const DisclaimerGateScreen();
    }
    return const AppShell();
  }
}
