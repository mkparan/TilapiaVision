import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localizations.dart';
import '../../core/app_theme.dart';
import '../../data/models/detection_result.dart';
import '../providers/detection_provider.dart';
import '../providers/locale_provider.dart';

/// Full-width "Save to Gallery" button for one [DetectionResult].
///
/// Saves the photo with its bounding box burned in (plus a caption strip
/// with the farm name, result and date) to the phone's photo
/// gallery (see [DetectionProvider.saveDetectionToGallery]) and reports
/// the outcome in a SnackBar. Used on both the Result screen (right
/// after a scan) and the History detail screen, so the two behave
/// identically.
///
/// Two looks: the default is a full-width outlined button (Result screen);
/// with [filled] it is the app's standard themed [ElevatedButton] — the
/// same design and colour the old Export button had — and is meant to sit
/// inside an [Expanded] in the History detail screen's action row.
class SaveToGalleryButton extends StatefulWidget {
  const SaveToGalleryButton({
    super.key,
    required this.result,
    this.filled = false,
    this.enabled = true,
  });

  final DetectionResult result;

  /// Render as the themed filled [ElevatedButton] instead of the outlined one.
  final bool filled;

  /// When false the button is disabled (e.g. while the record is being deleted).
  final bool enabled;

  @override
  State<SaveToGalleryButton> createState() => _SaveToGalleryButtonState();
}

class _SaveToGalleryButtonState extends State<SaveToGalleryButton> {
  bool _saving = false;

  /// Runs from a tap, not from build(), so it must not call
  /// `context.tr` (that helper uses `context.watch`, which Provider only
  /// allows during build). The language is read once, without watching,
  /// and everything that needs `context` is captured before the first
  /// await.
  Future<void> _save() async {
    final provider = context.read<DetectionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppLocalizations(context.read<LocaleProvider>().locale);

    // The result text burned into the gallery image, in the app's
    // current language (same wording as the History/Detail screens).
    final String resultLabel;
    switch (widget.result.label) {
      case DetectionLabel.presumptivePositive:
        resultLabel = strings.tr('detail_badge_presumptive');
        break;
      case DetectionLabel.lowMatch:
        resultLabel = strings.tr('detail_badge_low_match');
        break;
      case DetectionLabel.clear:
        resultLabel = strings.tr('history_card_no_lesions');
        break;
    }

    setState(() => _saving = true);
    final outcome = await provider.saveDetectionToGallery(widget.result,
        resultLabel: resultLabel);
    if (mounted) setState(() => _saving = false);

    final String messageKey;
    switch (outcome) {
      case GallerySaveOutcome.saved:
        messageKey = 'detail_gallery_saved';
        break;
      case GallerySaveOutcome.photoUnavailable:
        messageKey = 'detail_gallery_no_photo';
        break;
      case GallerySaveOutcome.accessDenied:
        messageKey = 'detail_gallery_denied';
        break;
      case GallerySaveOutcome.failed:
        messageKey = 'detail_gallery_failed';
        break;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(strings.tr(messageKey))));
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _saving || !widget.enabled;

    if (widget.filled) {
      // Same structure as the Export button it replaces: a plain themed
      // ElevatedButton (deep blue, white bold text) that shows a small
      // white spinner while busy.
      return ElevatedButton(
        onPressed: disabled ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(context.tr('detail_save_gallery')),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: disabled ? null : _save,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal,
          side: const BorderSide(color: AppColors.teal),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.photo_library_outlined, size: 18),
        label: Text(context.tr('detail_save_gallery')),
      ),
    );
  }
}
