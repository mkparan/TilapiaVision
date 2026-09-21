import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/providers/locale_provider.dart';

// ---------------------------------------------------------------------------
// Locale enum
// ---------------------------------------------------------------------------

enum AppLocale { english, tagalog, cebuano }

extension AppLocaleLabel on AppLocale {
  String get displayName {
    switch (this) {
      case AppLocale.english:
        return 'English';
      case AppLocale.tagalog:
        return 'Tagalog';
      case AppLocale.cebuano:
        return 'Cebuano (Bisaya)';
    }
  }
}

// ---------------------------------------------------------------------------
// AppLocalizations — string lookup table
// ---------------------------------------------------------------------------

class AppLocalizations {
  const AppLocalizations(this.locale);

  final AppLocale locale;

  /// Convenience: read from the widget tree.
  static AppLocalizations of(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    return AppLocalizations(locale);
  }

  /// Return translated string for [key], falling back to English.
  String tr(String key) {
    return _strings[locale]?[key] ?? _strings[AppLocale.english]![key] ?? key;
  }

  // -------------------------------------------------------------------------
  // Translation maps
  // -------------------------------------------------------------------------

  static const Map<AppLocale, Map<String, String>> _strings = {
    // ── ENGLISH ──────────────────────────────────────────────────────────────
    AppLocale.english: {
      // --- Nav bar ---
      'nav_scan': 'Scan',
      'nav_history': 'History',
      'nav_tips': 'Tips',

      // --- Disclaimer gate ---
      'disclaimer_subtitle':
          'Offline hemorrhagic lesion screening for Nile Tilapia',
      'disclaimer_section_title': 'Before You Begin',
      'disclaimer_body':
          'TilapiaVision screens for visual signs consistent with hemorrhagic disease. '
              'It is a detection support tool — not a veterinary diagnosis. Always confirm '
              'results with a qualified professional before treatment.',
      'disclaimer_checkbox':
          'I understand this is a presumptive screening tool, not a medical diagnosis.',
      'disclaimer_continue': 'Continue',

      // --- Farm profile setup ---
      'setup_title': 'Set Up Your Farm Profile',
      'setup_subtitle':
          'No account or internet needed — everything stays on this device.',
      'setup_field_label': 'FARM / OWNER NAME',
      'setup_field_hint': 'e.g., Doongan Grow-Out Pond',
      'setup_storage_notice':
          'Detection photos auto-delete after 30 days to save space. '
              'Detection records stay in your local CSV log until you clear or export them.',
      'setup_checkbox': 'I acknowledge the 30-day photo storage notice above.',
      'setup_cta': 'Create Profile & Start Scanning',

      // --- Camera capture ---
      'camera_pill_offline': 'Offline',
      'camera_pill_hold': 'Hold 15–30cm away',
      'camera_pill_glare': 'Avoid direct flash / sunlight glare',
      'camera_menu_settings': 'Settings',
      'camera_menu_about': 'About',

      // --- Result screen ---
      'result_processing': 'Analyzing image…',
      'result_processing_sub': 'Running fully on-device — no internet required',
      'result_try_again': 'Try Again',
      'result_timeout':
          'Analysis took too long. Try again in better lighting or closer range.',
      'result_error': 'Something went wrong analyzing this photo.',
      'result_not_tilapia': 'This doesn\'t appear to be a Tilapia.\n\n'
          'Please photograph a Nile Tilapia to run the disease screening.',
      'result_model_missing': 'A required model is not installed yet.',
      'result_model_failed': 'A required model loaded but failed to run.',
      'result_save': 'Save to History',
      'result_retake': 'Retake Photo',
      'result_scan_another': 'Scan Another',
      // result labels
      'badge_presumptive': 'Presumptive Positive',
      'heading_presumptive': 'Hemorrhagic Ulcer Detected',
      'body_presumptive':
          'Visual signs consistent with Aeromonas hydrophila (MAS). '
              'This is a presumptive screening result — not a lab-confirmed diagnosis.',
      'action_presumptive':
          'Recommended: Isolate this tilapia and consult a veterinary or aquaculture technician for proper diagnosis and treatment.',
      'badge_low_match': 'Low Match',
      'heading_low_match': 'Inconclusive Result',
      'body_low_match':
          'Some visual signs were detected, but confidence fell below the reliable threshold.',
      'action_low_match':
          'Recommended: Retake the photo in better lighting, or have a technician verify in person.',
      'badge_clear': 'No Lesions Detected',
      'heading_clear':
          'No lesions detected by the app. This is not confirmation the tilapia is healthy.',
      'body_clear':
          'No Aeromonas (MAS) hemorrhagic lesions were detected. Ensure the picture is clear. '
              'If you visibly see a lesion, please consult a technician, as the app specifically detects MAS '
              'and may not detect lesions from other diseases.',
      'action_clear':
          'This screens only visible external symptoms — it does not rule out '
              'internal or asymptomatic conditions.',

      // --- History ---
      'history_title': 'Detection History',
      'history_export_tooltip': 'Export CSV',
      'history_retention_notice':
          'Captured photos are automatically deleted after {days} days to save space. '
              'Detection records stay in this log until you delete or export them.',
      'history_empty': 'No detections saved yet.',
      'history_card_no_lesions': 'No Lesions Detected',
      'history_card_hemorrhagic': 'Hemorrhagic Ulcer',
      'history_expired': 'Expired',

      // --- Detail ---
      'detail_title': 'Detection Details',
      'detail_label_farm': 'Farm Profile',
      'detail_label_datetime': 'Date & Time',
      'detail_label_confidence': 'Confidence',
      'detail_label_class': 'Detected Class',
      'result_details_heading': 'DETECTION DETAILS',
      'detail_delete': 'Delete',
      'detail_save_gallery': 'Save to Gallery',
      'detail_gallery_saved': 'Saved to your gallery (TilapiaVision album).',
      'detail_gallery_no_photo':
          'The photo for this record has expired, so there is nothing to save.',
      'detail_gallery_denied':
          'Gallery access was denied. Allow it in your phone settings to save photos.',
      'detail_gallery_failed':
          'Could not save to the gallery. Please try again.',
      'detail_image_expired': 'Image Expired',
      'detail_image_expired_sub': 'Photos are removed after {days} days',
      'detail_dialog_title': 'Delete this detection?',
      'detail_dialog_body':
          'This removes it from your detection log permanently. This cannot be undone.',
      'detail_dialog_cancel': 'Cancel',
      'detail_dialog_confirm': 'Delete',
      // detail badges/headings
      'detail_badge_presumptive': 'Presumptive Positive',
      'detail_heading_presumptive': 'Hemorrhagic Ulcer',
      'detail_badge_low_match': 'Low Match',
      'detail_heading_low_match': 'Inconclusive Result',
      'detail_badge_clear': 'No Lesions Detected',
      'detail_heading_clear':
          'No lesions detected by the app. This is not confirmation the tilapia is healthy.',

      // --- Biosecurity ---
      'bio_title': 'Biosecurity Tips',
      'bio_subtitle':
          'Simple habits that reduce the risk of spreading disease between ponds.',
      'bio_tip1_title': 'Sanitize hands between ponds',
      'bio_tip1_body':
          'Wash or sanitize before and after handling tilapia from a different enclosure.',
      'bio_tip2_title': 'Disinfect nets & equipment',
      'bio_tip2_body':
          'Shared nets and basins are a common way disease travels between grow-out ponds.',
      'bio_tip3_title': 'Keep your phone dry',
      'bio_tip3_body':
          'Avoid direct device contact with pond water when capturing scans.',
      'bio_tip4_title': 'Isolate suspected cases',
      'bio_tip4_body':
          'Move a Presumptive Positive tilapia to a separate holding container while you seek verification.',

      // --- Settings ---
      'settings_title': 'Settings',
      'settings_language': 'Language',
      'settings_farm_label': 'Farm / Owner Name',
      'settings_farm_hint': 'Farm name',
      'settings_farm_save': 'Save Farm Name',
      'settings_farm_saved': 'Farm name saved',
      'settings_appearance': 'Appearance',
      'settings_dark_mode': 'Dark Mode',
      'settings_dark_mode_desc': 'Use a dark color scheme throughout the app',
      'settings_thresholds': 'Detection Thresholds',
      'settings_thresholds_desc':
          'Lower values flag more cases but risk more false positives. '
              'The species check is set high by default to avoid accepting random objects or misframed photos.',
      'settings_species_gate': 'Species check (Tilapia gate)',
      'settings_positive_threshold': 'Positive result threshold',
      'settings_model_status': 'Model Status',
      'settings_verifier': 'Species verifier',
      'settings_detector': 'Disease detector',
      'settings_stored_data': 'Stored Data',
      'settings_export_csv': 'Export detection log (CSV)',
      'settings_model_checking': 'Checking…',
      'settings_model_ready': 'Ready',
      'settings_model_not_ready': 'Not ready',

      // --- Developer options (unlocked from the About screen) ---
      'dev_options_title': 'Developer Options',
      'dev_options_hide': 'Hide',
      'dev_tap_progress': 'Developer options — taps remaining: {n}',
      'dev_unlocked': 'Developer options enabled. Find them in Settings.',
      'dev_already': 'Developer options are already enabled.',

      // --- About ---
      'about_title': 'About',
      'about_version': 'Version 1.0.0 — offline build',
      'about_card1_title': 'What this app does',
      'about_card1_body':
          'TilapiaVision screens photographs of Nile Tilapia for visual '
              'signs consistent with Motile Aeromonas Septicemia (hemorrhagic '
              'lesions). Everything runs on-device — no internet, no account.',
      'about_scope_title': 'What it can detect',
      'about_scope_body':
          'Only Aeromonas (Motile Aeromonas Septicemia) is detected, and only '
              'in Nile Tilapia. Other diseases, parasites, and other fish '
              'species are not covered by this app.',
      'about_card2_title': 'How it works',
      'about_card2_body':
          'Two models run in sequence. A species check first confirms the '
              'photo shows a tilapia; only then does the lesion detector run. '
              'That is why photographing something else returns "Not a '
              'Tilapia" rather than a disease result.',
      'about_card3_title': 'Important limitation',
      'about_card3_body':
          'This is a presumptive screening tool, not a veterinary '
              'diagnosis. It detects only visible external symptoms and '
              'cannot rule out internal or asymptomatic conditions. Always '
              'confirm with a qualified professional before treatment.',
      'about_card4_title': 'Your data',
      'about_card4_body':
          'Detection photos are deleted automatically after {days} days. '
              'Detection records stay until you delete or export them. Nothing leaves your '
              'device unless you share it yourself.',
    },

    // ── TAGALOG ──────────────────────────────────────────────────────────────
    AppLocale.tagalog: {
      // --- Nav bar ---
      'nav_scan': 'Scan',
      'nav_history': 'History',
      'nav_tips': 'Tips',

      // --- Disclaimer gate ---
      'disclaimer_subtitle':
          'Offline screening para sa sakit ng Nile Tilapia',
      'disclaimer_section_title': 'Bago Magsimula',
      'disclaimer_body':
          'Ang TilapiaVision ay sumusuri ng mga senyales ng hemorrhagic disease. '
              'Ito ay gabay lamang — hindi kapalit ng check-up sa beterinaryo. '
              'Laging komunsulta sa propesyonal bago magbigay ng lunas.',
      'disclaimer_checkbox':
          'Naiintindihan ko na ito ay gabay lamang at hindi pinal na diagnosis.',
      'disclaimer_continue': 'Magpatuloy',

      // --- Farm profile setup ---
      'setup_title': 'I-setup ang Iyong Farm Profile',
      'setup_subtitle':
          'Hindi kailangan ng account o internet — lahat ng data ay mananatili sa device mo.',
      'setup_field_label': 'PANGALAN NG FARM / MAY-ARI',
      'setup_field_hint': 'hal. Doongan Grow-Out Pond',
      'setup_storage_notice':
          'Awtomatikong nabubura ang mga pictures pagkalipas ng 30 araw para makatipid sa space. '
              'Ang mga detection record ay mananatili sa iyong log hanggang i-delete o i-export mo.',
      'setup_checkbox':
          'Naiintindihan ko ang 30-day storage notice ng mga pictures.',
      'setup_cta': 'Gumawa ng Profile at Mag-scan',

      // --- Camera capture ---
      'camera_pill_offline': 'Offline',
      'camera_pill_hold': 'Hawakan ng 15–30cm ang layo',
      'camera_pill_glare': 'Iwasan ang direktang araw o glare',
      'camera_menu_settings': 'Settings',
      'camera_menu_about': 'About',

      // --- Result screen ---
      'result_processing': 'Ina-analyze ang picture…',
      'result_processing_sub':
          'Gumagana mismo sa device — hindi kailangan ng internet',
      'result_try_again': 'Subukan Ulit',
      'result_timeout':
          'Masyadong matagal ang pag-analyze. Subukan ulit nang mas malapit o mas maliwanag.',
      'result_error': 'May nangyaring error sa pag-analyze ng picture na ito.',
      'result_not_tilapia': 'Mukhang hindi ito Tilapia.\n\n'
          'Kumuha ng picture ng Nile Tilapia para i-scan.',
      'result_model_missing':
          'Wala pa ang kailangang model.',
      'result_model_failed': 'Nag-fail ang model sa pag-run.',
      'result_save': 'I-save sa History',
      'result_retake': 'Kumuha Ulit ng Picture',
      'result_scan_another': 'Mag-scan Ulit',
      // result labels
      'badge_presumptive': 'Posibleng Positibo',
      'heading_presumptive': 'May Nakitang Hemorrhagic Ulcer',
      'body_presumptive':
          'May mga palatandaan na maaaring Aeromonas hydrophila (MAS). '
              'Ito ay paunang resulta lamang — hindi isang kumpirmadong diagnosis mula sa laboratoryo.',
      'action_presumptive':
          'Mungkahi: Ihiwalay ang isdang ito at sumangguni sa isang beterinaryo o technician para sa tamang diagnosis at lunas.',
      'badge_low_match': 'Hindi Tiyak',
      'heading_low_match': 'Hindi Malinaw ang Resulta',
      'body_low_match':
          'May nakitang ilang senyales, pero hindi umabot sa tamang confidence level para makumpirma.',
      'action_low_match':
          'Recommended: Kumuha ulit ng picture sa mas maliwanag na lugar, o ipa-check sa technician.',
      'badge_clear': 'Walang Natuklasang Sugat',
      'heading_clear': 'Mukhang Ligtas',
      'body_clear':
          'Walang nakitang Aeromonas (MAS) hemorrhagic na sugat. Siguruhing malinaw ang larawan. '
              'Kung may nakikita ka pa ring sugat, sumangguni sa technician dahil MAS lang ang dine-detect ng app '
              'at posibleng hindi makita ang sugat mula sa ibang sakit.',
      'action_clear':
          'Mga panlabas na sintomas lang ang nakikita nito — hindi ibig sabihin ay walang sakit sa loob ng katawan ang isda.',

      // --- History ---
      'history_title': 'Detection History',
      'history_export_tooltip': 'I-export as CSV',
      'history_retention_notice':
          'Awtomatikong nabubura ang mga pictures pagkalipas ng {days} araw para makatipid sa space. '
              'Ang mga record ay mananatili dito hanggang i-delete o i-export mo.',
      'history_empty': 'Wala pang na-save na records.',
      'history_card_no_lesions': 'Walang Nakitang Sugat',
      'history_card_hemorrhagic': 'Hemorrhagic Ulcer',
      'history_expired': 'Expired',

      // --- Detail ---
      'detail_title': 'Detection Details',
      'detail_label_farm': 'Farm Profile',
      'detail_label_datetime': 'Petsa at Oras',
      'detail_label_confidence': 'Confidence',
      'detail_label_class': 'Na-detect',
      'result_details_heading': 'DETECTION DETAILS',
      'detail_delete': 'I-delete',
      'detail_save_gallery': 'I-save sa Gallery',
      'detail_gallery_saved':
          'Na-save sa iyong gallery (TilapiaVision album).',
      'detail_gallery_no_photo':
          'Expired na ang picture para sa record na ito, kaya walang mai-save.',
      'detail_gallery_denied':
          'Hindi na-access ang gallery. Payagan ito sa settings ng iyong phone.',
      'detail_gallery_failed': 'Hindi na-save sa gallery. Subukan ulit.',
      'detail_image_expired': 'Expired na ang Picture',
      'detail_image_expired_sub':
          'Binubura ang mga picture pagkalipas ng {days} araw',
      'detail_dialog_title': 'I-delete itong record?',
      'detail_dialog_body':
          'Tuluyan na itong mabubura sa iyong log. Hindi na ito maibabalik.',
      'detail_dialog_cancel': 'I-cancel',
      'detail_dialog_confirm': 'I-delete',
      // detail badges/headings
      'detail_badge_presumptive': 'Posibleng Positibo',
      'detail_heading_presumptive': 'Hemorrhagic Ulcer',
      'detail_badge_low_match': 'Inconclusive',
      'detail_heading_low_match': 'Hindi Malinaw',
      'detail_badge_clear': 'Walang Nakitang Sugat',
      'detail_heading_clear': 'Mukhang Malinis',

      // --- Biosecurity ---
      'bio_title': 'Biosecurity Tips',
      'bio_subtitle':
          'Mga simpleng habit para hindi kumalat ang sakit sa ibang ponds.',
      'bio_tip1_title': 'Mag-sanitize ng kamay',
      'bio_tip1_body':
          'Maghugas o mag-sanitize bago at pagkatapos humawak ng isda mula sa ibang pond.',
      'bio_tip2_title': 'I-disinfect ang mga net at gamit',
      'bio_tip2_body':
          'Ang pag-share ng mga net at basin ay madalas maging dahilan ng pagkalat ng sakit.',
      'bio_tip3_title': 'Panatilihing tuyo ang phone',
      'bio_tip3_body':
          'Huwag hayaang mabasa ng pond water ang phone kapag kumukuha ng picture.',
      'bio_tip4_title': 'Ihiwalay ang mga posibleng may sakit',
      'bio_tip4_body':
          'Ilipat sa hiwalay na lalagyan ang isdang nag-test na Posibleng Positibo habang naghihintay ng kumpirmasyon.',

      // --- Settings ---
      'settings_title': 'Settings',
      'settings_language': 'Language',
      'settings_farm_label': 'PANGALAN NG FARM / MAY-ARI',
      'settings_farm_hint': 'Pangalan ng farm',
      'settings_farm_save': 'I-save ang Farm',
      'settings_farm_saved': 'Na-save na',
      'settings_appearance': 'Appearance',
      'settings_dark_mode': 'Dark Mode',
      'settings_dark_mode_desc': 'Gamitin ang dark theme sa app',
      'settings_thresholds': 'Detection Thresholds',
      'settings_thresholds_desc':
          'Kapag binabaan, mas marami ang made-detect pero baka dumami ang false positives. '
              'Mataas ang species check by default para hindi mag-scan ng ibang bagay o maling picture.',
      'settings_species_gate': 'Species check (Tilapia gate)',
      'settings_positive_threshold': 'Positive result threshold',
      'settings_model_status': 'Model Status',
      'settings_verifier': 'Species verifier',
      'settings_detector': 'Disease detector',
      'settings_stored_data': 'Stored Data',
      'settings_export_csv': 'I-export ang log (CSV)',
      'settings_model_checking': 'Checking…',
      'settings_model_ready': 'Ready',
      'settings_model_not_ready': 'Not ready',

      // --- Developer options (unlocked from the About screen) ---
      'dev_options_title': 'Developer Options',
      'dev_options_hide': 'I-hide',
      'dev_tap_progress': 'Developer options — taps left: {n}',
      'dev_unlocked':
          'Developer options enabled. Makikita mo na sa Settings.',
      'dev_already': 'Naka-enable na ang developer options.',

      // --- About ---
      'about_title': 'About',
      'about_version': 'Version 1.0.0 — offline build',
      'about_card1_title': 'Tungkol sa app na ito',
      'about_card1_body':
          'Sinusuri ng TilapiaVision ang pictures ng Nile Tilapia para sa senyales ng '
              'Motile Aeromonas Septicemia (hemorrhagic lesions). '
              'Gumagana ang lahat sa device mo — walang internet o account na kailangan.',
      'about_scope_title': 'Ano ang pwede nitong ma-detect',
      'about_scope_body':
          'Aeromonas (Motile Aeromonas Septicemia) lang ang nade-detect nito, at sa '
              'Nile Tilapia lang. Hindi sakop ng app na ito ang ibang sakit, '
              'parasites, at iba pang uri ng isda.',
      'about_card2_title': 'Paano ito gumagana',
      'about_card2_body':
          'May dalawang model na gumagana. Una nitong tinitingnan kung tilapia ang nasa picture '
              'bago i-run ang disease detector. Kaya "Not a Tilapia" ang lalabas kung ibang bagay ang pinicturan.',
      'about_card3_title': 'Important limitation',
      'about_card3_body':
          'Ito ay screening tool lang, at hindi kapalit ng diagnosis sa beterinaryo. '
              'Nakaka-detect lang ito ng panlabas na sintomas. '
              'Laging komunsulta sa propesyonal bago magbigay ng lunas.',
      'about_card4_title': 'Ang iyong data',
      'about_card4_body': 'Awtomatikong nabubura ang mga pictures pagkalipas ng {days} araw. '
          'Ang mga detection record ay mananatili hanggang i-delete o i-export mo. '
          'Walang data na lalabas sa device mo maliban na lang kung i-share mo ito.',
    },

    // ── CEBUANO / BISAYA ──────────────────────────────────────────────────────
    AppLocale.cebuano: {
      // --- Nav bar ---
      'nav_scan': 'Scan',
      'nav_history': 'History',
      'nav_tips': 'Tips',

      // --- Disclaimer gate ---
      'disclaimer_subtitle':
          'Offline screening sa hemorrhagic lesion para sa Nile Tilapia',
      'disclaimer_section_title': 'Sa Di Pa Ka Magsugod',
      'disclaimer_body':
          'Ang TilapiaVision mosusi sa mga timailhan sa hemorrhagic disease. '
              'Guide lang ni — dili hulip sa check-up sa beterinaryo. '
              'Kanunay mangonsulta sa propesyonal sa dili pa mohatag og tambal.',
      'disclaimer_checkbox':
          'Nakasabot ko nga guide lang ni ug dili final nga diagnosis.',
      'disclaimer_continue': 'Padayon',

      // --- Farm profile setup ---
      'setup_title': 'I-setup ang Imong Farm Profile',
      'setup_subtitle':
          'Di kinahanglan og account o internet — tanang data magpabilin sa imong device.',
      'setup_field_label': 'NGALAN SA FARM / TAG-IYA',
      'setup_field_hint': 'ex. Doongan Grow-Out Pond',
      'setup_storage_notice':
          'Automatic nga ma-delete ang mga pictures inig abot sa 30 ka adlaw para makatipid sa space. '
              'Ang mga detection record magpabilin sa imong log hangtod i-delete o i-export nimo.',
      'setup_checkbox':
          'Nakasabot ko sa 30-day storage notice sa mga pictures.',
      'setup_cta': 'Paghimo og Profile ug Mag-scan',

      // --- Camera capture ---
      'camera_pill_offline': 'Offline',
      'camera_pill_hold': 'Gunitan og 15–30cm kalayo',
      'camera_pill_glare': 'Likayi ang direktang adlaw o glare',
      'camera_menu_settings': 'Settings',
      'camera_menu_about': 'About',

      // --- Result screen ---
      'result_processing': 'Gi-analyze ang picture…',
      'result_processing_sub':
          'Nag-run sa mismong device — walay internet gikinahanglan',
      'result_try_again': 'Sulayi Usab',
      'result_timeout':
          'Dugay ra ang pag-analyze. Sulayi usab, ipaduol or sa mas hayag nga lugar.',
      'result_error': 'Naay sayop nahitabo samtang nag-analyze sa picture.',
      'result_not_tilapia': 'Murag dili ni Tilapia.\n\n'
          'Pagkuha og picture sa Nile Tilapia aron ma-scan para sa sakit.',
      'result_model_missing':
          'Wala pa ang gikinahanglan nga model.',
      'result_model_failed': 'Nag-fail sa pag-run ang model.',
      'result_save': 'I-save sa History',
      'result_retake': 'Pagkuha Usab og Picture',
      'result_scan_another': 'Mag-scan Usab',
      // result labels
      'badge_presumptive': 'Posibleng Positibo',
      'heading_presumptive': 'Adunay Nakitang Hemorrhagic Ulcer',
      'body_presumptive':
          'Adunay mga timailhan sa Aeromonas hydrophila (MAS). '
              'Kini usa lamang ka pasiunang resulta — dili usa ka kompirmado nga pagdayagnos gikan sa laboratoryo.',
      'action_presumptive':
          'Pahimangno: Ilahi kining isda ug magpakisayod sa usa ka beterinaryo o technician alang sa saktong pagdayagnos ug pagtambal.',
      'badge_low_match': 'Dili Tino',
      'heading_low_match': 'Di Klaro nga Resulta',
      'body_low_match':
          'Naay nakitang mga senyales, pero wa kaabot sa sakto nga confidence level aron makompirmar.',
      'action_low_match':
          'Recommended: Kuhai usab og picture sa mas hayag nga lugar, o ipa-check sa usa ka technician.',
      'badge_clear': 'Walay Nakitang Samad',
      'heading_clear': 'Mopatim-aw nga Luwas',
      'body_clear':
          'Walay nakitang Aeromonas (MAS) hemorrhagic nga samad. Siguroha nga klaro ang hulagway. '
              'Kung aduna gihapon kay makita nga samad, ipatan-aw sa technician tungod kay MAS ra ang ma-detect sa app '
              'ug posibleng dili makita ang samad gikan sa laing sakit.',
      'action_clear':
          'Mga panggawas nga sintomas lang ang makit-an niini — dili buot pasabot nga walay sakit sa sulod sa lawas ang isda.',

      // --- History ---
      'history_title': 'Detection History',
      'history_export_tooltip': 'I-export as CSV',
      'history_retention_notice':
          'Automatic nga ma-delete ang mga pictures inig abot sa {days} ka adlaw para makatipid sa space. '
              'Magpabilin ang mga record diri hangtod i-delete o i-export nimo.',
      'history_empty': 'Wala pay na-save nga mga record.',
      'history_card_no_lesions': 'Walay Nakitang Samad',
      'history_card_hemorrhagic': 'Hemorrhagic Ulcer',
      'history_expired': 'Expired',

      // --- Detail ---
      'detail_title': 'Detection Details',
      'detail_label_farm': 'Farm Profile',
      'detail_label_datetime': 'Petsa ug Oras',
      'detail_label_confidence': 'Confidence',
      'detail_label_class': 'Na-detect',
      'result_details_heading': 'DETECTION DETAILS',
      'detail_delete': 'I-delete',
      'detail_save_gallery': 'I-save sa Gallery',
      'detail_gallery_saved':
          'Na-save sa imong gallery (TilapiaVision album).',
      'detail_gallery_no_photo':
          'Expired na ang picture para niining record, busa walay ma-save.',
      'detail_gallery_denied':
          'Wa gi-allow ang gallery access. E-allow sa settings sa imong phone.',
      'detail_gallery_failed':
          'Wala ma-save sa gallery. Palihug sulayi usab.',
      'detail_image_expired': 'Expired na nga Picture',
      'detail_image_expired_sub':
          'I-delete ang mga picture human sa {days} ka adlaw',
      'detail_dialog_title': 'I-delete kining record?',
      'detail_dialog_body':
          'Mawala na gyud ni sa imong log. Dili na kini mabalik.',
      'detail_dialog_cancel': 'I-cancel',
      'detail_dialog_confirm': 'I-delete',
      // detail badges/headings
      'detail_badge_presumptive': 'Posibleng Positibo',
      'detail_heading_presumptive': 'Hemorrhagic Ulcer',
      'detail_badge_low_match': 'Inconclusive',
      'detail_heading_low_match': 'Di Klaro nga Resulta',
      'detail_badge_clear': 'Walay Nakitang Samad',
      'detail_heading_clear': 'Murag Limpyo',

      // --- Biosecurity ---
      'bio_title': 'Biosecurity Tips',
      'bio_subtitle':
          'Mga simple nga habit para dili mokatap ang sakit sa ubang ponds.',
      'bio_tip1_title': 'Pag-sanitize sa kamot',
      'bio_tip1_body':
          'Panghugas o pag-sanitize sa kamot una ug human mogunit og isda gikan sa laing pond.',
      'bio_tip2_title': 'I-disinfect ang mga net ug gamit',
      'bio_tip2_body':
          'Ang pag-share og mga net ug basin sagad rason ngano mokatap ang sakit sa lain-laing pond.',
      'bio_tip3_title': 'Ayaw basaa ang phone',
      'bio_tip3_body':
          'Likayi nga mabasa sa tubig sa pond ang imong phone inig kuha nimo og picture.',
      'bio_tip4_title': 'Ilahi ang posibleng naay sakit',
      'bio_tip4_body':
          'Ibalhin sa laing butanganan ang isda nga ni-test og Posibleng Positibo samtang naghulat og kompirmasyon.',

      // --- Settings ---
      'settings_title': 'Settings',
      'settings_language': 'Language',
      'settings_farm_label': 'NGALAN SA FARM / TAG-IYA',
      'settings_farm_hint': 'Ngalan sa farm',
      'settings_farm_save': 'I-save ang Farm',
      'settings_farm_saved': 'Na-save na',
      'settings_appearance': 'Appearance',
      'settings_dark_mode': 'Dark Mode',
      'settings_dark_mode_desc': 'Mogamit og dark theme sa tibuok app',
      'settings_thresholds': 'Detection Thresholds',
      'settings_thresholds_desc':
          'Kung paubsan, mas daghan ma-detect pero basig modaghan ang false positives. '
              'Gituyo nga taas ang species check by default aron dili mo-scan og laing butang o bati nga picture.',
      'settings_species_gate': 'Species check (Tilapia gate)',
      'settings_positive_threshold': 'Positive result threshold',
      'settings_model_status': 'Model Status',
      'settings_verifier': 'Species verifier',
      'settings_detector': 'Disease detector',
      'settings_stored_data': 'Stored Data',
      'settings_export_csv': 'I-export ang log (CSV)',
      'settings_model_checking': 'Checking…',
      'settings_model_ready': 'Ready Na',
      'settings_model_not_ready': 'Dili pa ready',

      // --- Developer options (unlocked from the About screen) ---
      'dev_options_title': 'Developer Options',
      'dev_options_hide': 'I-hide',
      'dev_tap_progress':
          'Developer options — nabilin nga taps: {n}',
      'dev_unlocked':
          'Naka-enable na ang developer options. Makit-an nimo sa Settings.',
      'dev_already': 'Naka-enable na ang developer options.',

      // --- About ---
      'about_title': 'About',
      'about_version': 'Version 1.0.0 — offline build',
      'about_card1_title': 'Unsay ginabuhat ani nga app',
      'about_card1_body':
          'Ginasusi sa TilapiaVision ang pictures sa Nile Tilapia para mangita og senyales sa '
              'Motile Aeromonas Septicemia (hemorrhagic lesions). '
              'Tanang proseso anaa sa imong device — walay internet o account gikinahanglan.',
      'about_scope_title': 'Unsay ma-detect niini',
      'about_scope_body':
          'Aeromonas (Motile Aeromonas Septicemia) lang ang ma-detect niini, ug sa '
              'Nile Tilapia lang. Ang ubang sakit, parasites, ug ubang klase sa isda dili ma-detect aning app.',
      'about_card2_title': 'Unsaon ni paggana',
      'about_card2_body':
          'Naay duha ka model nga mo-run. Una niining tinoon kung tilapia ang naa sa picture, '
              'una pa mo-run ang disease detector. Mao nang "Not a Tilapia" ang mogawas kung laing butang ang gipicturan.',
      'about_card3_title': 'Important limitation',
      'about_card3_body':
          'Screening tool lang ni, ug dili puli sa diagnosis sa beterinaryo. '
              'Mga panggawas nga sintomas lang ang ma-detect niini. '
              'Kanunay mangonsulta sa propesyonal sa dili pa mohatag og tambal.',
      'about_card4_title': 'Ang imong data',
      'about_card4_body': 'Automatic nga ma-delete ang mga pictures inig abot sa {days} ka adlaw. '
          'Ang mga detection record magpabilin hangtod i-delete o i-export nimo. '
          'Walay data nga mogawas sa imong device gawas lang kung i-share nimo.',
    },
  };
}

// ---------------------------------------------------------------------------
// BuildContext extension — context.tr('key')
// ---------------------------------------------------------------------------

extension AppLocalizationsX on BuildContext {
  String tr(String key) => AppLocalizations.of(this).tr(key);

  /// Variant that replaces `{days}` (or any placeholder) in the translation.
  String trFmt(String key, Map<String, String> args) {
    var s = tr(key);
    for (final entry in args.entries) {
      s = s.replaceAll('{${entry.key}}', entry.value);
    }
    return s;
  }
}
