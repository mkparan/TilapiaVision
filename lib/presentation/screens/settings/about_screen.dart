import 'package:flutter/material.dart';

import '../../../core/app_localizations.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('about_title'))),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/tilapiavision_logo.png',
              width: 66,
              height: 66,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text('TilapiaVision',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.heading)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(context.tr('about_version'),
              style: TextStyle(fontSize: 12, color: AppColors.slate)),
        ),
        const SizedBox(height: 24),
        _card(context, 'about_card1_title', 'about_card1_body'),
        _card(context, 'about_card2_title', 'about_card2_body'),
        _card(context, 'about_card3_title', 'about_card3_body'),
        _cardFmt(context, 'about_card4_title', 'about_card4_body',
            {'days': '${DetectionConfig.imageRetentionDays}'}),
      ]),
    );
  }

  Widget _card(BuildContext ctx, String titleKey, String bodyKey) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ctx.tr(titleKey),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: AppColors.heading)),
          const SizedBox(height: 6),
          Text(ctx.tr(bodyKey),
              style: TextStyle(
                  fontSize: 12.5, height: 1.6, color: AppColors.slate)),
        ]),
      );

  Widget _cardFmt(BuildContext ctx, String titleKey, String bodyKey,
          Map<String, String> args) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ctx.tr(titleKey),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: AppColors.heading)),
          const SizedBox(height: 6),
          Text(ctx.trFmt(bodyKey, args),
              style: TextStyle(
                  fontSize: 12.5, height: 1.6, color: AppColors.slate)),
        ]),
      );
}
