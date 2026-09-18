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
      'result_not_tilapia':
          'This doesn\'t appear to be a Tilapia.\n\n'
              'Please photograph a Nile Tilapia fish to run the disease screening.',
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
          'Recommended: Isolate this fish and consult a veterinary or '
              'aquaculture technician for confirmation.',
      'badge_low_match': 'Low Match',
      'heading_low_match': 'Inconclusive Result',
      'body_low_match':
          'Some visual signs were detected, but confidence fell below the reliable threshold.',
      'action_low_match':
          'Recommended: Retake the photo in better lighting, or have a technician verify in person.',
      'badge_clear': 'No Lesions Detected',
      'heading_clear': 'Looks Clear',
      'body_clear':
          'No hemorrhagic lesions were detected in this image. Continue routine monitoring.',
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
      'detail_export_tooltip': 'Export',
      'detail_label_farm': 'Farm Profile',
      'detail_label_datetime': 'Date & Time',
      'detail_label_confidence': 'Confidence',
      'detail_label_class': 'Detected Class',
      'detail_delete': 'Delete',
      'detail_export': 'Export',
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
      'detail_heading_clear': 'Looks Clear',

      // --- Biosecurity ---
      'bio_title': 'Biosecurity Tips',
      'bio_subtitle':
          'Simple habits that reduce the risk of spreading disease between ponds.',
      'bio_tip1_title': 'Sanitize hands between ponds',
      'bio_tip1_body':
          'Wash or sanitize before and after handling fish from a different enclosure.',
      'bio_tip2_title': 'Disinfect nets & equipment',
      'bio_tip2_body':
          'Shared nets and basins are a common way disease travels between grow-out ponds.',
      'bio_tip3_title': 'Keep your phone dry',
      'bio_tip3_body':
          'Avoid direct device contact with pond water when capturing scans.',
      'bio_tip4_title': 'Isolate suspected cases',
      'bio_tip4_body':
          'Move a Presumptive Positive fish to a separate holding container while you seek verification.',

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

      // --- About ---
      'about_title': 'About',
      'about_version': 'Version 1.0.0 — offline build',
      'about_card1_title': 'What this app does',
      'about_card1_body':
          'TilapiaVision screens photographs of Nile Tilapia for visual '
              'signs consistent with Motile Aeromonas Septicemia (hemorrhagic '
              'lesions). Everything runs on-device — no internet, no account.',
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
      'nav_scan': 'I-scan',
      'nav_history': 'Kasaysayan',
      'nav_tips': 'Mga Tip',

      // --- Disclaimer gate ---
      'disclaimer_subtitle':
          'Offline na pagsusuri ng hemorrhagic lesion para sa Nile Tilapia',
      'disclaimer_section_title': 'Bago Magsimula',
      'disclaimer_body':
          'Sinusuri ng TilapiaVision ang mga biswal na palatandaan na naaayon sa hemorrhagic na sakit. '
              'Ito ay isang pantulong na kagamitan sa pagtukoy — hindi isang beterinaryong diagnosis. '
              'Palaging kumpirmahin ang mga resulta sa isang kwalipikadong propesyonal bago mag-treat.',
      'disclaimer_checkbox':
          'Naiintindihan ko na ito ay isang presumptive na kagamitan sa pag-screen, hindi isang medikal na diagnosis.',
      'disclaimer_continue': 'Magpatuloy',

      // --- Farm profile setup ---
      'setup_title': 'I-set Up ang Iyong Profile ng Bukid',
      'setup_subtitle':
          'Walang account o internet na kailangan — lahat ay nananatili sa device na ito.',
      'setup_field_label': 'PANGALAN NG BUKID / MAY-ARI',
      'setup_field_hint': 'hal., Doongan Grow-Out Pond',
      'setup_storage_notice':
          'Ang mga larawan ng detection ay awtomatikong natatanggal pagkatapos ng 30 araw upang makatipid ng espasyo. '
              'Ang mga rekord ng detection ay nananatili sa iyong lokal na CSV log hanggang i-clear o i-export mo ang mga ito.',
      'setup_checkbox':
          'Tinatanggap ko ang abiso sa 30-araw na imbakan ng larawan sa itaas.',
      'setup_cta': 'Lumikha ng Profile at Magsimulang Mag-scan',

      // --- Camera capture ---
      'camera_pill_offline': 'Offline',
      'camera_pill_hold': 'Hawakan ng 15–30cm ang layo',
      'camera_pill_glare': 'Iwasan ang direktang flash / araw na sinag',
      'camera_menu_settings': 'Mga Setting',
      'camera_menu_about': 'Tungkol Sa',

      // --- Result screen ---
      'result_processing': 'Sinusuri ang larawan…',
      'result_processing_sub':
          'Tumatakbo nang buo sa device — walang internet na kailangan',
      'result_try_again': 'Subukang Muli',
      'result_timeout':
          'Masyadong matagal ang pagsusuri. Subukang muli sa mas magandang ilaw o mas malapit na layo.',
      'result_error': 'May nangyaring mali sa pagsusuri ng larawang ito.',
      'result_not_tilapia':
          'Mukhang hindi ito Tilapia.\n\n'
              'Mangyaring kumuha ng larawan ng isang Nile Tilapia upang patakbuhin ang pagsusuri ng sakit.',
      'result_model_missing':
          'Ang isang kinakailangang modelo ay hindi pa naka-install.',
      'result_model_failed':
          'Ang isang kinakailangang modelo ay na-load ngunit nabigo sa pagpapatakbo.',
      'result_save': 'I-save sa Kasaysayan',
      'result_retake': 'Kumuha Muli ng Larawan',
      'result_scan_another': 'Mag-scan ng Isa Pa',
      // result labels
      'badge_presumptive': 'Presumptive Positibo',
      'heading_presumptive': 'Natuklasang Hemorrhagic Ulcer',
      'body_presumptive':
          'Mga biswal na palatandaan na naaayon sa Aeromonas hydrophila (MAS). '
              'Ito ay isang presumptive na resulta ng pag-screen — hindi isang lab-confirmed na diagnosis.',
      'action_presumptive':
          'Inirerekomenda: Ihiwalay angisdang ito at kumonsulta sa isang beterinaryo o '
              'aquaculture technician para sa kumpirmasyon.',
      'badge_low_match': 'Mababang Tugma',
      'heading_low_match': 'Hindi Malinaw na Resulta',
      'body_low_match':
          'Ilang biswal na palatandaan ang natuklasan, ngunit ang kumpiyansa ay bumaba sa ibaba ng maaasahang threshold.',
      'action_low_match':
          'Inirerekomenda: Kumuha muli ng larawan sa mas magandang ilaw, o hayaang i-verify ng technician nang personal.',
      'badge_clear': 'Walang Natuklasang Lesyon',
      'heading_clear': 'Mukhang Malinaw',
      'body_clear':
          'Walang hemorrhagic lesyon ang natuklasan sa larawang ito. Magpatuloy sa regular na pagsubaybay.',
      'action_clear':
          'Sinusuri lamang nito ang mga nakikitang panlabas na sintomas — hindi nito tinatanggal ang '
              'panloob o asymptomatic na kondisyon.',

      // --- History ---
      'history_title': 'Kasaysayan ng Detection',
      'history_export_tooltip': 'I-export ang CSV',
      'history_retention_notice':
          'Ang mga nakunang larawan ay awtomatikong natatanggal pagkatapos ng {days} araw upang makatipid ng espasyo. '
              'Ang mga rekord ng detection ay nananatili sa log na ito hanggang i-delete o i-export mo ang mga ito.',
      'history_empty': 'Wala pang naka-save na detection.',
      'history_card_no_lesions': 'Walang Natuklasang Lesyon',
      'history_card_hemorrhagic': 'Hemorrhagic Ulcer',
      'history_expired': 'Nag-expire',

      // --- Detail ---
      'detail_title': 'Mga Detalye ng Detection',
      'detail_export_tooltip': 'I-export',
      'detail_label_farm': 'Profile ng Bukid',
      'detail_label_datetime': 'Petsa at Oras',
      'detail_label_confidence': 'Kumpiyansa',
      'detail_label_class': 'Natuklasang Klase',
      'detail_delete': 'Burahin',
      'detail_export': 'I-export',
      'detail_image_expired': 'Nag-expire ang Larawan',
      'detail_image_expired_sub':
          'Tinatanggal ang mga larawan pagkatapos ng {days} araw',
      'detail_dialog_title': 'Burahin ang detection na ito?',
      'detail_dialog_body':
          'Tinatanggal nito nang permanente mula sa iyong detection log. Hindi ito maaaring i-undo.',
      'detail_dialog_cancel': 'Kanselahin',
      'detail_dialog_confirm': 'Burahin',
      // detail badges/headings
      'detail_badge_presumptive': 'Presumptive Positibo',
      'detail_heading_presumptive': 'Hemorrhagic Ulcer',
      'detail_badge_low_match': 'Mababang Tugma',
      'detail_heading_low_match': 'Hindi Malinaw na Resulta',
      'detail_badge_clear': 'Walang Natuklasang Lesyon',
      'detail_heading_clear': 'Mukhang Malinaw',

      // --- Biosecurity ---
      'bio_title': 'Mga Tip sa Biosecurity',
      'bio_subtitle':
          'Mga simpleng gawi na nagbabawas ng panganib ng pagkalat ng sakit sa pagitan ng mga pond.',
      'bio_tip1_title': 'Linisin ang mga kamay sa pagitan ng mga pond',
      'bio_tip1_body':
          'Maghugas o mag-sanitize bago at pagkatapos hawakan ang mga isda mula sa ibang kulungan.',
      'bio_tip2_title': 'Disinfect ang mga net at kagamitan',
      'bio_tip2_body':
          'Ang mga ibinabahaging net at basin ay isang karaniwang paraan ng pagkalat ng sakit sa mga grow-out pond.',
      'bio_tip3_title': 'Panatilihing tuyo ang iyong telepono',
      'bio_tip3_body':
          'Iwasan ang direktang pakikipag-ugnayan ng device sa tubig ng pond kapag kumukuha ng mga scan.',
      'bio_tip4_title': 'Ihiwalay ang mga pinaghihinalaang kaso',
      'bio_tip4_body':
          'Ilipat ang isang Presumptive Positive na isda sa isang hiwalay na lalagyan habang naghahanap ng kumpirmasyon.',

      // --- Settings ---
      'settings_title': 'Mga Setting',
      'settings_language': 'Wika',
      'settings_farm_label': 'Pangalan ng Bukid / May-ari',
      'settings_farm_hint': 'Pangalan ng bukid',
      'settings_farm_save': 'I-save ang Pangalan ng Bukid',
      'settings_farm_saved': 'Na-save ang pangalan ng bukid',
      'settings_appearance': 'Hitsura',
      'settings_dark_mode': 'Madilim na Mode',
      'settings_dark_mode_desc':
          'Gamitin ang madilim na kulay sa buong app',
      'settings_thresholds': 'Mga Threshold ng Detection',
      'settings_thresholds_desc':
          'Ang mas mababang halaga ay nagtatanda ng mas maraming kaso ngunit nagdudulot ng mas maraming maling positibo. '
              'Ang pagsusuri sa species ay itinakda nang mataas bilang default upang maiwasan ang pagtanggap ng mga random na bagay o maling framed na larawan.',
      'settings_species_gate': 'Pagsusuri sa species (Tilapia gate)',
      'settings_positive_threshold': 'Threshold ng positibong resulta',
      'settings_model_status': 'Katayuan ng Modelo',
      'settings_verifier': 'Verifier ng species',
      'settings_detector': 'Detector ng sakit',
      'settings_stored_data': 'Nakaimbak na Data',
      'settings_export_csv': 'I-export ang detection log (CSV)',
      'settings_model_checking': 'Sinusuri…',
      'settings_model_ready': 'Handa',
      'settings_model_not_ready': 'Hindi handa',

      // --- About ---
      'about_title': 'Tungkol Sa',
      'about_version': 'Bersyon 1.0.0 — offline build',
      'about_card1_title': 'Ano ang ginagawa ng app na ito',
      'about_card1_body':
          'Sinusuri ng TilapiaVision ang mga larawan ng Nile Tilapia para sa mga biswal na '
              'palatandaan na naaayon sa Motile Aeromonas Septicemia (hemorrhagic lesions). '
              'Lahat ay tumatakbo sa device — walang internet, walang account.',
      'about_card2_title': 'Paano ito gumagana',
      'about_card2_body':
          'Dalawang modelo ang tumatakbo nang sunud-sunod. Unang kumpirmahin ng pagsusuri sa species na '
              'ipinapakita ng larawan ang isang tilapia; pagkatapos lamang ay tatakbo ang lesyon detector. '
              'Kaya naman ang pagkuha ng larawan ng iba pang bagay ay nagbabalik ng "Hindi Tilapia" '
              'sa halip na isang resulta ng sakit.',
      'about_card3_title': 'Mahalagang limitasyon',
      'about_card3_body':
          'Ito ay isang presumptive na kagamitan sa pag-screen, hindi isang beterinaryong diagnosis. '
              'Natatukoy lamang nito ang mga nakikitang panlabas na sintomas at hindi maaaring '
              'ibukod ang mga panloob o asymptomatic na kondisyon. Palaging kumpirmahin sa isang '
              'kwalipikadong propesyonal bago mag-treat.',
      'about_card4_title': 'Ang iyong data',
      'about_card4_body':
          'Ang mga larawan ng detection ay awtomatikong natatanggal pagkatapos ng {days} araw. '
              'Ang mga rekord ng detection ay nananatili hanggang i-delete o i-export mo ang mga ito. '
              'Walang lumalabas sa iyong device maliban kung ibahagi mo ang mga ito mismo.',
    },

    // ── CEBUANO / BISAYA ──────────────────────────────────────────────────────
    AppLocale.cebuano: {
      // --- Nav bar ---
      'nav_scan': 'I-scan',
      'nav_history': 'Kasaysayan',
      'nav_tips': 'Mga Tip',

      // --- Disclaimer gate ---
      'disclaimer_subtitle':
          'Offline nga pagsusi sa hemorrhagic lesion alang sa Nile Tilapia',
      'disclaimer_section_title': 'Sa Wala Pa Magsugod',
      'disclaimer_body':
          'Gisusi sa TilapiaVision ang mga biswal nga timailhan nga nahiuyon sa hemorrhagic nga sakit. '
              'Kini usa ka himan sa suporta sa pagdepekto — dili usa ka beterinaryong diagnosis. '
              'Kanunay nga kumpirmahin ang mga resulta sa usa ka kwalipikadong propesyonal sa wala pa mag-treat.',
      'disclaimer_checkbox':
          'Nasabtan nako nga kini usa ka presumptive nga himan sa pag-screen, dili usa ka medikal nga diagnosis.',
      'disclaimer_continue': 'Padayon',

      // --- Farm profile setup ---
      'setup_title': 'I-set Up ang Imong Profile sa Pond',
      'setup_subtitle':
          'Walay account o internet nga gikinahanglan — ang tanan magpabilin sa device nga kini.',
      'setup_field_label': 'NGALAN SA POND / TAG-IYA',
      'setup_field_hint': 'hal., Doongan Grow-Out Pond',
      'setup_storage_notice':
          'Ang mga hulagway sa detection awtomatikong mapapala human sa 30 ka adlaw aron makatigom og espasyo. '
              'Ang mga rekord sa detection magpabilin sa imong lokal nga CSV log hangtod i-clear o i-export nimo kini.',
      'setup_checkbox':
          'Giila nako ang abiso sa 30-ka-adlaw nga pagtipig sa hulagway sa ibabaw.',
      'setup_cta': 'Paghimo og Profile ug Magsugod sa Pag-scan',

      // --- Camera capture ---
      'camera_pill_offline': 'Offline',
      'camera_pill_hold': 'Ibitay og 15–30cm ang gilay-on',
      'camera_pill_glare': 'Likayi ang direktang flash / silaw sa adlaw',
      'camera_menu_settings': 'Mga Setting',
      'camera_menu_about': 'Mahitungod Sa',

      // --- Result screen ---
      'result_processing': 'Gisusi ang hulagway…',
      'result_processing_sub':
          'Nagdagan sa device — walay internet nga gikinahanglan',
      'result_try_again': 'Sulayi Pag-usab',
      'result_timeout':
          'Dugay kaayo ang pagsusi. Sulayi pag-usab sa mas maayong suga o mas duol nga gilay-on.',
      'result_error':
          'May nahitabo nga sayop sa pagsusi sa hulagway nga kini.',
      'result_not_tilapia':
          'Daw dili kini Tilapia.\n\n'
              'Palihug kumuha og hulagway sa usa ka Nile Tilapia aron ipadagan ang pagsusi sa sakit.',
      'result_model_missing':
          'Ang usa ka kinahanglang modelo wala pa ma-install.',
      'result_model_failed':
          'Ang usa ka kinahanglang modelo na-load apan napakyas sa pagdagan.',
      'result_save': 'I-save sa Kasaysayan',
      'result_retake': 'Kumuha Pag-usab og Hulagway',
      'result_scan_another': 'Mag-scan og Lain',
      // result labels
      'badge_presumptive': 'Presumptive Positibo',
      'heading_presumptive': 'Nadiskubreng Hemorrhagic Ulcer',
      'body_presumptive':
          'Mga biswal nga timailhan nga nahiuyon sa Aeromonas hydrophila (MAS). '
              'Kini usa ka presumptive nga resulta sa pag-screen — dili usa ka lab-confirmed nga diagnosis.',
      'action_presumptive':
          'Girekomenda: Ihimulag kining isda ug kumonsulta sa usa ka beterinaryo o '
              'aquaculture technician alang sa kumpirmasyon.',
      'badge_low_match': 'Ubos nga Katugma',
      'heading_low_match': 'Dili Klaro nga Resulta',
      'body_low_match':
          'Pipila ka biswal nga timailhan ang nadiskubre, apan ang pagsalig mihulog sa ubos sa kasaligang threshold.',
      'action_low_match':
          'Girekomenda: Kumuha pag-usab og hulagway sa mas maayong suga, o pasusiha sa usa ka technician.',
      'badge_clear': 'Walay Nadiskubreng Lesyon',
      'heading_clear': 'Murag Maayong',
      'body_clear':
          'Walay hemorrhagic lesyon ang nadiskubre sa hulagway nga kini. Padayon sa regular nga pagmonitor.',
      'action_clear':
          'Gisusi lamang niini ang mga makita nga panlabas nga sintomas — dili niini matangtang ang '
              'sulod o asymptomatic nga kondisyon.',

      // --- History ---
      'history_title': 'Kasaysayan sa Detection',
      'history_export_tooltip': 'I-export ang CSV',
      'history_retention_notice':
          'Ang mga nakuha nga hulagway awtomatikong mapapala human sa {days} ka adlaw aron makatigom og espasyo. '
              'Ang mga rekord sa detection magpabilin sa log nga kini hangtod i-delete o i-export nimo kini.',
      'history_empty': 'Wala pay na-save nga detection.',
      'history_card_no_lesions': 'Walay Nadiskubreng Lesyon',
      'history_card_hemorrhagic': 'Hemorrhagic Ulcer',
      'history_expired': 'Nag-expire',

      // --- Detail ---
      'detail_title': 'Mga Detalye sa Detection',
      'detail_export_tooltip': 'I-export',
      'detail_label_farm': 'Profile sa Pond',
      'detail_label_datetime': 'Petsa ug Oras',
      'detail_label_confidence': 'Pagsalig',
      'detail_label_class': 'Nadiskubreng Klase',
      'detail_delete': 'Papason',
      'detail_export': 'I-export',
      'detail_image_expired': 'Nag-expire ang Hulagway',
      'detail_image_expired_sub':
          'Ang mga hulagway gikuha human sa {days} ka adlaw',
      'detail_dialog_title': 'Papason ba kining detection?',
      'detail_dialog_body':
          'Permanente kining matangtang gikan sa imong detection log. Dili kini mabawi.',
      'detail_dialog_cancel': 'Kanselahon',
      'detail_dialog_confirm': 'Papason',
      // detail badges/headings
      'detail_badge_presumptive': 'Presumptive Positibo',
      'detail_heading_presumptive': 'Hemorrhagic Ulcer',
      'detail_badge_low_match': 'Ubos nga Katugma',
      'detail_heading_low_match': 'Dili Klaro nga Resulta',
      'detail_badge_clear': 'Walay Nadiskubreng Lesyon',
      'detail_heading_clear': 'Murag Maayo',

      // --- Biosecurity ---
      'bio_title': 'Mga Tip sa Biosecurity',
      'bio_subtitle':
          'Mga simpleng batasan nga nagpaminos sa risgo sa pagkuyanap sa sakit tali sa mga pond.',
      'bio_tip1_title': 'Limpyoi ang mga kamot tali sa mga pond',
      'bio_tip1_body':
          'Hugasi o mag-sanitize sa wala pa ug human makiangay sa mga isda gikan sa laing kulungan.',
      'bio_tip2_title': 'I-disinfect ang mga pukot ug kagamitan',
      'bio_tip2_body':
          'Ang mga gigamit nga pukot ug basin usa ka kasagaran nga paagi sa pagkuyanap sa sakit sa mga grow-out pond.',
      'bio_tip3_title': 'Ipadayon nga uga ang imong telepono',
      'bio_tip3_body':
          'Likayi ang direktang kontak sa device sa tubig sa pond kung nagkuha og mga scan.',
      'bio_tip4_title': 'Ihimulag ang mga gihinayang kaso',
      'bio_tip4_body':
          'Balhin ang usa ka Presumptive Positive nga isda ngadto sa usa ka bulag nga sudlanan samtang nagpangita og kumpirmasyon.',

      // --- Settings ---
      'settings_title': 'Mga Setting',
      'settings_language': 'Pinulongan',
      'settings_farm_label': 'Ngalan sa Pond / Tag-iya',
      'settings_farm_hint': 'Ngalan sa pond',
      'settings_farm_save': 'I-save ang Ngalan sa Pond',
      'settings_farm_saved': 'Na-save ang ngalan sa pond',
      'settings_appearance': 'Panagway',
      'settings_dark_mode': 'Ngitngit nga Mode',
      'settings_dark_mode_desc':
          'Gamita ang ngitngit nga kolor sa tibuok app',
      'settings_thresholds': 'Mga Threshold sa Detection',
      'settings_thresholds_desc':
          'Ang mas ubos nga kantidad nagmarka og mas daghang kaso apan nagdugon og mas daghang sayop nga positibo. '
              'Ang pagsusi sa species gibutang nga taas sa default aron malikayan ang pagtanggap sa random nga mga butang o maling framed nga hulagway.',
      'settings_species_gate': 'Pagsusi sa species (Tilapia gate)',
      'settings_positive_threshold': 'Threshold sa positibong resulta',
      'settings_model_status': 'Kahimtang sa Modelo',
      'settings_verifier': 'Verifier sa species',
      'settings_detector': 'Detector sa sakit',
      'settings_stored_data': 'Gitipig nga Data',
      'settings_export_csv': 'I-export ang detection log (CSV)',
      'settings_model_checking': 'Gisusi…',
      'settings_model_ready': 'Andam',
      'settings_model_not_ready': 'Dili andam',

      // --- About ---
      'about_title': 'Mahitungod Sa',
      'about_version': 'Bersyon 1.0.0 — offline build',
      'about_card1_title': 'Unsa ang gibuhat sa app nga kini',
      'about_card1_body':
          'Gisusi sa TilapiaVision ang mga hulagway sa Nile Tilapia alang sa mga biswal nga '
              'timailhan nga nahiuyon sa Motile Aeromonas Septicemia (hemorrhagic lesions). '
              'Ang tanan nagdagan sa device — walay internet, walay account.',
      'about_card2_title': 'Unsaon kini paggana',
      'about_card2_body':
          'Duha ka modelo ang nagdagan sa sunud-sunod. Unang gikumpirma sa pagsusi sa species nga '
              'gipakita sa hulagway ang usa ka tilapia; pagkahuman lamang nagdagan ang lesyon detector. '
              'Mao kana ngano nga ang pagkuha og hulagway sa laing butang nagbalik og "Dili Tilapia" '
              'kaysa sa usa ka resulta sa sakit.',
      'about_card3_title': 'Importanteng limitasyon',
      'about_card3_body':
          'Kini usa ka presumptive nga himan sa pag-screen, dili usa ka beterinaryong diagnosis. '
              'Nakit-an lamang niini ang mga makita nga panlabas nga sintomas ug dili kini '
              'makatangtang sa sulod o asymptomatic nga kondisyon. Kanunay nga kumpirmahin sa usa ka '
              'kwalipikadong propesyonal sa wala pa mag-treat.',
      'about_card4_title': 'Ang imong data',
      'about_card4_body':
          'Ang mga hulagway sa detection awtomatikong mapapala human sa {days} ka adlaw. '
              'Ang mga rekord sa detection magpabilin hangtod i-delete o i-export nimo kini. '
              'Walay mogawas sa imong device gawas kung ikaw mismo ang magpaambit niini.',
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
