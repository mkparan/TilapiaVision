import 'package:flutter_test/flutter_test.dart';
import 'package:tilapiavision/core/app_localizations.dart';

/// Guards the strings added for the About "scope" card and for Save to
/// Gallery. AppLocalizations.tr() silently falls back to English (and
/// then to the key itself) when a translation is missing, so a plain
/// "does it render" check would never notice a forgotten language.
void main() {
  const newKeys = [
    'about_scope_title',
    'about_scope_body',
    'detail_save_gallery',
    'detail_gallery_saved',
    'detail_gallery_no_photo',
    'detail_gallery_denied',
    'detail_gallery_failed',
    'dev_options_title',
    'dev_options_hide',
    'dev_tap_progress',
    'dev_unlocked',
    'dev_already',
  ];

  const english = AppLocalizations(AppLocale.english);

  for (final locale in AppLocale.values) {
    test('${locale.name} defines every new string itself', () {
      final l10n = AppLocalizations(locale);
      for (final key in newKeys) {
        expect(l10n.tr(key), isNot(key), reason: '$key is missing entirely');
        if (locale != AppLocale.english) {
          expect(
            l10n.tr(key),
            isNot(english.tr(key)),
            reason: '$key falls back to English in ${locale.name}',
          );
        }
      }
    });
  }

  test('the tap countdown keeps its {n} placeholder in every language', () {
    // The About screen fills {n} in with replaceAll; a translation that
    // dropped it would show a countdown with no number.
    for (final locale in AppLocale.values) {
      expect(AppLocalizations(locale).tr('dev_tap_progress'), contains('{n}'),
          reason: locale.name);
    }
  });

  test('About scope card names Aeromonas and Nile Tilapia in every language',
      () {
    for (final locale in AppLocale.values) {
      final body = AppLocalizations(locale).tr('about_scope_body');
      expect(body, contains('Aeromonas'), reason: locale.name);
      expect(body, contains('Nile Tilapia'), reason: locale.name);
    }
  });

  test('{days} placeholders survive translation in every language', () {
    // trFmt() fills {days} in; a translation that dropped it would show
    // the retention period as nothing at all.
    const keysWithDays = [
      'history_retention_notice',
      'detail_image_expired_sub',
      'about_card4_body',
    ];
    for (final locale in AppLocale.values) {
      for (final key in keysWithDays) {
        expect(AppLocalizations(locale).tr(key), contains('{days}'),
            reason: '$key in ${locale.name}');
      }
    }
  });

  test('Cebuano camera hint says "hold" (Gunit-), not "Ibitay" (hang)', () {
    const cebuano = AppLocalizations(AppLocale.cebuano);
    // Accepts either verb form ("Guniti" or "Gunitan") — both replace the
    // original "Ibitay" (hang) mistranslation, which is the actual bug.
    expect(cebuano.tr('camera_pill_hold'), contains('Gunit'));
    expect(cebuano.tr('camera_pill_hold'), isNot(contains('Ibitay')));
  });
}
