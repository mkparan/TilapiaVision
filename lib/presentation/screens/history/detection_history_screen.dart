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
import 'detection_detail_screen.dart';

/// Reads straight from [DetectionProvider.history] (backed by the
/// CSV log via [DetectionRepository]). Tapping a card opens
/// [DetectionDetailScreen]. The "Image Expired" fallback card
/// demonstrates the graceful-degradation behavior from Section 3.3:
/// metadata survives the 30-day cache window even after the photo
/// itself has been deleted.
class DetectionHistoryScreen extends StatefulWidget {
  const DetectionHistoryScreen({super.key});

  @override
  State<DetectionHistoryScreen> createState() => _DetectionHistoryScreenState();
}

class _DetectionHistoryScreenState extends State<DetectionHistoryScreen> {
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetectionProvider>().loadHistory();
    });
  }

  Future<void> _handleExport() async {
    setState(() => _exporting = true);
    try {
      await context.read<DetectionProvider>().exportCsv();
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<DetectionProvider>().history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection History'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: history.isEmpty || _exporting ? null : _handleExport,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepBlue),
                  )
                : const Icon(LucideIcons.fileSpreadsheet),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          const _RetentionNotice(),
          Expanded(
            child: history.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _HistoryCard(result: history[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RetentionNotice extends StatelessWidget {
  const _RetentionNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.ice, borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.info, size: 16, color: AppColors.teal),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Captured photos are automatically deleted after '
                '${DetectionConfig.imageRetentionDays} days to save space. '
                'Detection records stay in this log until you delete or export them.',
                style: const TextStyle(fontSize: 11.3, height: 1.5, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.ice, borderRadius: BorderRadius.circular(16)),
            child: const Icon(LucideIcons.history, size: 26, color: AppColors.teal),
          ),
          const SizedBox(height: 14),
          const Text('No detections saved yet.', style: TextStyle(color: AppColors.slate, fontSize: 13)),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.result});

  final DetectionResult result;

  static final _storageService = StorageService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _storageService.imageExists(result.imagePath),
      builder: (context, snapshot) {
        final imageAvailable = snapshot.data ?? false;
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DetectionDetailScreen(result: result)),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: imageAvailable
                        ? Image.file(File(result.imagePath!), fit: BoxFit.cover)
                        : Container(
                            color: AppColors.slateLight,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.imageOff, size: 17, color: AppColors.slate),
                                SizedBox(height: 2),
                                Text(
                                  'Expired',
                                  style: TextStyle(fontSize: 7, color: AppColors.slate, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_titleFor(result), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: _dotColorFor(result.label)),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            DateFormat('MMM d, h:mm a').format(result.timestamp),
                            style: const TextStyle(fontSize: 11, color: AppColors.slate),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  result.label == DetectionLabel.clear ? '—' : '${(result.confidenceScore * 100).round()}%',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _dotColorFor(result.label)),
                ),
                const SizedBox(width: 6),
                const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.slate),
              ],
            ),
          ),
        );
      },
    );
  }

  String _titleFor(DetectionResult r) {
    if (r.label == DetectionLabel.clear) return 'No Lesions Detected';
    return 'Hemorrhagic Ulcer';
  }

  Color _dotColorFor(DetectionLabel label) {
    switch (label) {
      case DetectionLabel.presumptivePositive:
        return AppColors.amber;
      case DetectionLabel.lowMatch:
        return AppColors.slate;
      case DetectionLabel.clear:
        return AppColors.mint;
    }
  }
}
