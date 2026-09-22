import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';
import '../../core/app_theme.dart';

void showTermsAndConditionsModal(BuildContext context, {VoidCallback? onAgree}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _TermsAndConditionsContent(onAgree: onAgree),
  );
}

class _TermsAndConditionsContent extends StatelessWidget {
  final VoidCallback? onAgree;

  const _TermsAndConditionsContent({this.onAgree});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('tc_title'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            _Section(
              title: context.tr('tc_scope_title'),
              body: context.tr('tc_scope_body'),
            ),
            const SizedBox(height: 16),
            _Section(
              title: context.tr('tc_dataset_title'),
              body: context.tr('tc_dataset_body'),
            ),
            const SizedBox(height: 16),
            _Section(
              title: context.tr('tc_retention_title'),
              body: context.tr('tc_retention_body'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onAgree != null) {
                    onAgree!();
                  }
                },
                child: Text(onAgree != null ? context.tr('tc_agree') : context.tr('tc_close')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.slate,
          ),
        ),
      ],
    );
  }
}
