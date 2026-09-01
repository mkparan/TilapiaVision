import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../data/models/detection_result.dart';
import '../../providers/detection_provider.dart';
import '../../widgets/bounding_box_painter.dart';

/// Runs detection on [imageFile] via [DetectionProvider] and renders
/// whichever state comes back: processing, timeout, error, or one of
/// the three result labels (Presumptive Positive / Low Match / Clear).
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.imageFile, required this.farmProfile});

  final File imageFile;
  final String farmProfile;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetectionProvider>().runDetection(widget.imageFile, farmProfile: widget.farmProfile);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DetectionProvider>(
      builder: (context, provider, _) {
        switch (provider.status) {
          case ScanStatus.idle:
          case ScanStatus.processing:
            return _ProcessingView(imageFile: widget.imageFile);
          case ScanStatus.timeout:
            return _ErrorView(
              message: 'Analysis took too long. Try again in better lighting or closer range.',
              onRetry: () => Navigator.of(context).pop(),
            );
          case ScanStatus.error:
            return _ErrorView(
              message: 'Something went wrong analyzing this photo.',
              onRetry: () => Navigator.of(context).pop(),
            );
          case ScanStatus.success:
            final result = provider.lastResult!;
            return _ResultView(imageFile: widget.imageFile, result: result);
        }
      },
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({required this.imageFile});

  final File imageFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.35,
            child: Image.file(imageFile, fit: BoxFit.cover),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 28),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1424).withOpacity(0.85),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.mint),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing image…',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Running fully on-device — no internet required',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.slate),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTheme {
  const _ResultTheme({
    required this.accentColor,
    required this.dashed,
    required this.badgeBg,
    required this.badgeFg,
    required this.badgeText,
    required this.heading,
    required this.body,
    required this.actionBg,
    required this.actionText,
  });

  final Color accentColor;
  final bool dashed;
  final Color badgeBg;
  final Color badgeFg;
  final String badgeText;
  final String heading;
  final String body;
  final Color actionBg;
  final String actionText;

  static _ResultTheme of(DetectionLabel label) {
    switch (label) {
      case DetectionLabel.presumptivePositive:
        return const _ResultTheme(
          accentColor: AppColors.amber,
          dashed: false,
          badgeBg: Color(0xFFFFF3DC),
          badgeFg: AppColors.amberDark,
          badgeText: 'Presumptive Positive',
          heading: 'Hemorrhagic Ulcer Detected',
          body: 'Visual signs consistent with Aeromonas hydrophila (MAS). '
              'This is a presumptive screening result — not a lab-confirmed diagnosis.',
          actionBg: Color(0xFFFFF6E5),
          actionText: 'Recommended: Isolate this fish and consult a veterinary or '
              'aquaculture technician for confirmation.',
        );
      case DetectionLabel.lowMatch:
        return const _ResultTheme(
          accentColor: AppColors.slate,
          dashed: true,
          badgeBg: AppColors.slateLight,
          badgeFg: Color(0xFF475569),
          badgeText: 'Low Match',
          heading: 'Inconclusive Result',
          body: 'Some visual signs were detected, but confidence fell below the reliable threshold.',
          actionBg: AppColors.slateLight,
          actionText: 'Recommended: Retake the photo in better lighting, or have a technician verify in person.',
        );
      case DetectionLabel.clear:
        return const _ResultTheme(
          accentColor: AppColors.mint,
          dashed: false,
          badgeBg: Color(0xFFDBF7EF),
          badgeFg: AppColors.mintDark,
          badgeText: 'No Lesions Detected',
          heading: 'Looks Clear',
          body: 'No hemorrhagic lesions were detected in this image. Continue routine monitoring.',
          actionBg: Color(0xFFE4FBF4),
          actionText: 'This screens only visible external symptoms — it does not rule out '
              'internal or asymptomatic conditions.',
        );
    }
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.imageFile, required this.result});

  final File imageFile;
  final DetectionResult result;

  @override
  Widget build(BuildContext context) {
    final theme = _ResultTheme.of(result.label);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: Image.file(imageFile, fit: BoxFit.cover),
                ),
                if (result.boundingBox != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: BoundingBoxPainter(
                        box: result.boundingBox!,
                        color: theme.accentColor,
                        label: '${(result.confidenceScore * 100).round()}%',
                        dashed: theme.dashed,
                      ),
                    ),
                  ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: SafeArea(
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: theme.badgeBg, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      theme.badgeText,
                      style: TextStyle(color: theme.badgeFg, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    theme.heading,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  const SizedBox(height: 8),
                  Text(theme.body, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black54)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(color: theme.actionBg, borderRadius: BorderRadius.circular(14)),
                    child: Text(theme.actionText, style: const TextStyle(fontSize: 11.8, height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.label != DetectionLabel.lowMatch)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.read<DetectionProvider>().saveLastResultToHistory();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Save to History'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retake Photo'),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Scan Another'),
            ),
          ],
        ),
      ),
    );
  }
}
