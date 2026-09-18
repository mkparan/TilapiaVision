import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'data/repositories/detection_repository.dart';
import 'presentation/app_shell.dart';
import 'presentation/providers/detection_provider.dart';
import 'presentation/providers/farm_profile_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/onboarding/disclaimer_gate_screen.dart';
// To revert to the mock engine for UI testing, uncomment the line
// below and swap the engine: parameter back to MockDetectionEngine().
// import 'services/detection/mock_detection_engine.dart';
import 'services/detection/tflite_detection_engine.dart';
import 'services/storage_service.dart';
import 'services/verification/tflite_tilapia_verifier.dart';

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
        // Loads the persisted language preference before any UI renders.
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
        // Loads persisted thresholds (and the dark mode preference)
        // and applies them before any scan/screen can run — see
        // settings_provider.dart. The root router below waits for
        // this to finish loading.
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(
          create: (_) => DetectionProvider(
            // Real on-device YOLO11n disease detector + species verifier.
            // To revert to the mock for UI testing, swap engine: back to
            // MockDetectionEngine() and remove the verifier parameter.
            engine: TFLiteDetectionEngine(),
            repository: DetectionRepository(),
            storageService: StorageService(),
            verifier: TFLiteTilapiaVerifier(),
          ),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'TilapiaVision',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode:
                settings.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
            // SplashScreen is the entry point on every cold start.
            // It animates for ~2.5 s then hands off to RootRouter.
            home: const _SplashEntry(),
          );
        },
      ),
    );
  }
}

/// Thin entry-point widget that passes RootRouter to _SplashScreen,
/// keeping _SplashScreen itself decoupled from provider lookups.
class _SplashEntry extends StatelessWidget {
  const _SplashEntry();

  @override
  Widget build(BuildContext context) {
    return const _SplashScreen(nextScreen: RootRouter());
  }
}

// ---------------------------------------------------------------------------
// Splash screen — shown on every cold start
// ---------------------------------------------------------------------------

/// Branded animated splash screen.
///
/// Displays the TilapiaVision logo with a fade-in + scale-up animation
/// for [_displayDuration], then fades into [nextScreen].
class _SplashScreen extends StatefulWidget {
  const _SplashScreen({required this.nextScreen});
  final Widget nextScreen;

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _displayDuration = Duration(milliseconds: 2500);
  static const _animDuration = Duration(milliseconds: 900);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _animDuration);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    // Schedule navigation after the splash duration. addPostFrameCallback
    // ensures Navigator is available before Timer fires.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(_displayDuration, _navigateNext);
    });
  }

  void _navigateNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Splash is intentionally brand-colored (navy) regardless of theme.
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -- Logo --------------------------------------------------
                Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Image.asset(
                    'assets/images/tilapiavision_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 28),

                // -- App name ----------------------------------------------
                const Text(
                  'TilapiaVision',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // -- Tagline -----------------------------------------------
                const Text(
                  'AI-Powered Fish Health Detection',
                  style: TextStyle(
                    color: AppColors.mint,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 56),

                // -- Loading indicator -------------------------------------
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.mint.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Root router
// ---------------------------------------------------------------------------

/// Decides which "page zero" to show: the mandatory onboarding flow
/// for first launch, or straight into the tab-bar app shell for a
/// returning user with a saved Farm Profile. Waits for both the farm
/// profile AND the persisted detection settings to finish loading, so
/// a scan can never run against stale in-memory threshold defaults.
///
/// Public so [_SplashScreen] can reference it without import tricks.
class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final farmProfileProvider = context.watch<FarmProfileProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    if (farmProfileProvider.loading || settingsProvider.loading || localeProvider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // AppColors' theme-reactive getters (ink, surface, appBackground,
    // etc. — see app_theme.dart) are plain static fields, not
    // Provider/InheritedWidget state, so they don't trigger a rebuild
    // of every descendant on their own. Keying the page-zero widget on
    // the current dark-mode flag forces Flutter to throw away and
    // rebuild the whole subtree whenever it changes, so every screen
    // re-resolves its colors instead of only the widgets that happen
    // to watch SettingsProvider directly.
    final themeKey = ValueKey('theme-${settingsProvider.darkModeEnabled}');
    if (!farmProfileProvider.hasProfile) {
      return DisclaimerGateScreen(key: themeKey);
    }
    return AppShell(key: themeKey);
  }
}
