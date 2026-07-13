import 'dart:io';

import 'i_tilapia_verifier.dart';

/// Always confirms — unblocks 100% of app development before a real
/// verifier exists.
///
/// Recommended next step (see the App Development Masterplan):
/// transfer-train a small MobileNetV2/V3-Small binary classifier
/// (tilapia vs. not-tilapia) on ~150–250 images. It's a much lighter
/// lift than a second full detector since it's binary classification,
/// not localization. Whatever you build, implement it behind
/// [ITilapiaVerifier] — no screen needs to change when you swap this
/// stub out.
class StubTilapiaVerifier implements ITilapiaVerifier {
  @override
  Future<bool> isTilapia(File image) async => true;
}
