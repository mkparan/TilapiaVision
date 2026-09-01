import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../data/models/detection_result.dart';
import '../../../services/storage_service.dart';
import '../../providers/detection_provider.dart';
import '../../widgets/bounding_box_painter.dart';

/// Full detail view for one detection record — reachable by tapping
/// any card on [DetectionHistoryScreen]. Shows the cached photo (or
/// the expired-archive fallback if it's past the 30-day window),
/// every stored field, and lets the farmer delete the record or
/// export the photo + a text summary together.
class DetectionDetailScreen extends StatefulWidget {
  const DetectionDetailScreen({super.key, required this.result});

  final DetectionResult result;

  @override
  State<DetectionDetailScreen> createState() => _DetectionDetailScreenState();
}

class _DetectionDetailScreenState extends State<DetectionDetailScreen> {
  bool _busy = false;

  Future<void> _handleExport() async {
    setState(() => _busy = true);
    try {
      await context
          .read<DetectionProvider>()
          .exportSingleDetection(widget.result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this detection?'),
        content: const Text(
          'This removes it from your detection log permanently. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.amberDark, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final id = widget.result.id;
    if (id == null) return;

    setState(() => _busy = true);
    await context.read<DetectionProvider>().deleteDetection(id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final theme = _detailThemeFor(result.label);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Details'),
        actions: [
          IconButton(
            tooltip: 'Export',
            onPressed: _busy ? null : _handleExport,
            icon: const Icon(LucideIcons.share2),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          FutureBuilder<bool>(
            future: StorageService().imageExists(result.imagePath),
            builder: (context, snapshot) {
              final available = snapshot.data ?? false;
              return SizedBox(
                height: 260,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    available
                        ? Image.file(File(result.imagePath!), fit: BoxFit.cover)
                        : Container(
                            color: AppColors.slateLight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.imageOff,
                                    size: 34, color: AppColors.slate),
                                const SizedBox(height: 10),
                                const Text(
                                  'Image Expired',
                                  style: TextStyle(
                                      color: AppColors.slate,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Photos are removed after ${DetectionConfig.imageRetentionDays} days',
                                  style: const TextStyle(
                                      color: AppColors.slate, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                    if (available && result.boundingBox != null)
                      CustomPaint(
                        painter: BoundingBoxPainter(
                          box: result.boundingBox!,
                          color:
                              result.label == DetectionLabel.presumptivePositive
                                  ? AppColors.amber
                                  : AppColors.slate,
                          label: '${(result.confidenceScore * 100).round()}%',
                          dashed: result.label == DetectionLabel.lowMatch,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: theme.badgeBg,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    theme.badgeText,
                    style: TextStyle(
                        color: theme.badgeFg,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(height: 14),
                Text(theme.heading,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                _InfoRow(
                    icon: LucideIcons.user,
                    label: 'Farm Profile',
                    value: result.farmProfile),
                _InfoRow(
                  icon: LucideIcons.clock,
                  label: 'Date & Time',
                  value: DateFormat('MMM d, yyyy — h:mm a')
                      .format(result.timestamp),
                ),
                if (result.label != DetectionLabel.clear)
                  _InfoRow(
                    icon: LucideIcons.circleAlert,
                    label: 'Confidence',
                    value: '${(result.confidenceScore * 100).round()}%',
                  ),
                _InfoRow(
                    icon: LucideIcons.fileSpreadsheet,
                    label: 'Detected Class',
                    value: result.diseaseClass),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _handleDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.amberDark,
                  side: const BorderSide(color: AppColors.amberDark),
                ),
                child: const Text('Delete'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _busy ? null : _handleExport,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Export'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slate,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTheme {
  const _DetailTheme({
    required this.badgeBg,
    required this.badgeFg,
    required this.badgeText,
    required this.heading,
  });

  final Color badgeBg;
  final Color badgeFg;
  final String badgeText;
  final String heading;
}

_DetailTheme _detailThemeFor(DetectionLabel label) {
  switch (label) {
    case DetectionLabel.presumptivePositive:
      return const _DetailTheme(
        badgeBg: Color(0xFFFFF3DC),
        badgeFg: AppColors.amberDark,
        badgeText: 'Presumptive Positive',
        heading: 'Hemorrhagic Ulcer',
      );
    case DetectionLabel.lowMatch:
      return const _DetailTheme(
        badgeBg: AppColors.slateLight,
        badgeFg: Color(0xFF475569),
        badgeText: 'Low Match',
        heading: 'Inconclusive Result',
      );
    case DetectionLabel.clear:
      return const _DetailTheme(
        badgeBg: Color(0xFFDBF7EF),
        badgeFg: AppColors.mintDark,
        badgeText: 'No Lesions Detected',
        heading: 'Looks Clear',
      );
  }
}
