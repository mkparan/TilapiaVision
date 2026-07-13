import 'dart:io';

/// Gate that confirms the photographed subject is actually a Nile
/// Tilapia before the (more expensive) disease detection model ever
/// runs — the "Tilapia subject verification gate" described in the
/// two-stage detection pipeline.
///
/// Unlike the disease detector, no algorithm was locked in for this
/// gate at proposal stage. See [StubTilapiaVerifier] for the
/// recommended build-now / verify-later approach.
abstract class ITilapiaVerifier {
  Future<bool> isTilapia(File image);
}
