import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/app_localizations.dart';
import '../../../core/app_theme.dart';
import '../../../data/models/detection_result.dart';
import '../../providers/detection_provider.dart';
import '../../widgets/bounding_box_painter.dart'; // exports BoundingBoxPainter & MultiBoxPainter
import '../../widgets/save_to_gallery_button.dart';

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
              message: context.tr('result_timeout'),
              onRetry: () => Navigator.of(context).pop(),
            );
          case ScanStatus.error:
            return _ErrorView(
              message: context.tr('result_error'),
              onRetry: () => Navigator.of(context).pop(),
            );
          case ScanStatus.notTilapia:
            return _ErrorView(
              message: context.tr('result_not_tilapia'),
              onRetry: () => Navigator.of(context).pop(),
            );
          case ScanStatus.modelMissing:
            return _ErrorView(
              message: provider.errorDetail.isNotEmpty
                  ? provider.errorDetail
                  : context.tr('result_model_missing'),
              onRetry: () => Navigator.of(context).pop(),
            );
          case ScanStatus.modelFailed:
            return _ErrorView(
              message: provider.errorDetail.isNotEmpty
                  ? provider.errorDetail
                  : context.tr('result_model_failed'),
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
    // Deliberately fixed dark chrome regardless of app theme — this is
    // a full-bleed photo-review overlay, not a themed page.
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
                color: const Color(0xFF0F1424).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.mint),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('result_processing'),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('result_processing_sub'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 11.5),
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
              Icon(Icons.error_outline, size: 40, color: AppColors.slate),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                child: Text(context.tr('result_try_again')),
              ),
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
    required this.badgeKey,
    required this.headingKey,
    required this.bodyKey,
    required this.actionBg,
    required this.actionKey,
  });

  final Color accentColor;
  final bool dashed;
  final Color badgeBg;
  final Color badgeFg;
  final String badgeKey;
  final String headingKey;
  final String bodyKey;
  final Color actionBg;
  final String actionKey;

  static _ResultTheme of(DetectionLabel label) {
    final isDark = AppColors.isDark;
    switch (label) {
      case DetectionLabel.presumptivePositive:
        return _ResultTheme(
          accentColor: AppColors.amber,
          dashed: false,
          badgeBg: isDark ? const Color(0xFF3D2E0F) : const Color(0xFFFFF3DC),
          badgeFg: AppColors.amberDark,
          badgeKey: 'badge_presumptive',
          headingKey: 'heading_presumptive',
          bodyKey: 'body_presumptive',
          actionBg: isDark ? const Color(0xFF2E2410) : const Color(0xFFFFF6E5),
          actionKey: 'action_presumptive',
        );
      case DetectionLabel.lowMatch:
        return _ResultTheme(
          accentColor: AppColors.slate,
          dashed: true,
          badgeBg: AppColors.slateLight,
          badgeFg: isDark ? const Color(0xFFC3CCDA) : const Color(0xFF475569),
          badgeKey: 'badge_low_match',
          headingKey: 'heading_low_match',
          bodyKey: 'body_low_match',
          actionBg: AppColors.slateLight,
          actionKey: 'action_low_match',
        );
      case DetectionLabel.clear:
        return _ResultTheme(
          accentColor: AppColors.mint,
          dashed: false,
          badgeBg: isDark ? const Color(0xFF10382E) : const Color(0xFFDBF7EF),
          badgeFg: AppColors.mintDark,
          badgeKey: 'badge_clear',
          headingKey: 'heading_clear',
          bodyKey: 'body_clear',
          actionBg: isDark ? const Color(0xFF102D25) : const Color(0xFFE4FBF4),
          actionKey: 'action_clear',
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
                if (result.boundingBoxes.isNotEmpty)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: MultiBoxPainter(
                        boxes: result.boundingBoxes,
                        color: theme.accentColor,
                        fallbackLabel: '${(result.confidenceScore * 100).round()}%',
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
                      context.tr(theme.badgeKey),
                      style: TextStyle(color: theme.badgeFg, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(theme.headingKey),
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.heading),
                  ),
                  const SizedBox(height: 8),
                  Text(context.tr(theme.bodyKey), style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.slate)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(color: theme.actionBg, borderRadius: BorderRadius.circular(14)),
                    child: Text(context.tr(theme.actionKey), style: TextStyle(fontSize: 11.8, height: 1.5, color: AppColors.ink)),
                  ),

                  // Detection details. Shown here so a farmer sees the
                  // same figures the History detail screen reports,
                  // without needing to save first and navigate back in.
                  //
                  // Confidence is deliberately hidden for a Clear
                  // result: with no detection there is no prediction to
                  // attach a confidence to, and showing "0%" would read
                  // as "0% chance of disease" rather than "nothing was
                  // found", which is the opposite of what it means.
                  const SizedBox(height: 20),
                  Text(
                    context.tr('result_details_heading'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: LucideIcons.user,
                    label: context.tr('detail_label_farm'),
                    value: result.farmProfile,
                  ),
                  _DetailRow(
                    icon: LucideIcons.clock,
                    label: context.tr('detail_label_datetime'),
                    value: DateFormat('MMM d, yyyy — h:mm a')
                        .format(result.timestamp),
                  ),
                  if (result.label != DetectionLabel.clear)
                    _DetailRow(
                      icon: LucideIcons.circleAlert,
                      label: context.tr('detail_label_confidence'),
                      value: '${(result.confidenceScore * 100).round()}%',
                      valueColor: theme.badgeFg,
                    ),
                  _DetailRow(
                    icon: LucideIcons.fileSpreadsheet,
                    label: context.tr('detail_label_class'),
                    value: result.diseaseClass,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
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
                  child: Text(context.tr('result_save')),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.tr('result_retake')),
                ),
              ),
            // Keep the annotated photo on the phone. Works for every
            // outcome, including Low Match (which is never written to
            // History) — the farmer decides whether to keep it.
            const SizedBox(height: 10),
            SaveToGalleryButton(result: result),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr('result_scan_another')),
            ),
          ],
        ),
      ),
    );
  }
}

/// One label/value line in the Result screen's detection details
/// block. Mirrors the `_InfoRow` used by the History detail screen so
/// the same detection reads identically in both places.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.slate),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11.5, color: AppColors.slate),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
