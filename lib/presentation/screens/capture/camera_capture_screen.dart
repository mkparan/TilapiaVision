import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../providers/farm_profile_provider.dart';
import '../result/result_screen.dart';

/// The main "Scan" tab. Guided capture enforces the field-condition
/// guidance from Chapter 3: hold 15–30cm away, fill roughly 50% of
/// the frame, avoid direct flash/glare.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  bool _busy = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initializeFuture = _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      // Camera unavailable (e.g. running on an emulator/desktop
      // without one). The viewfinder falls back to a placeholder
      // below so the rest of the UI stays testable without hardware.
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Toggles the camera's torch (steady fill light) on/off. Uses
  /// torch rather than a one-shot flash — a steady light is easier
  /// to frame a close-up shot under than a flash burst, and this
  /// still respects the "avoid direct flash/glare" guidance since
  /// it's the farmer's choice to enable it, not a forced default.
  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await controller.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } catch (_) {
      // Some devices/emulators don't support torch mode — fail
      // quietly rather than interrupting the capture flow over a
      // non-essential feature.
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) return;

    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      await _goToResult(File(file.path));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final XFile? picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;
      await _goToResult(File(picked.path));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _goToResult(File image) async {
    final farmName =
        context.read<FarmProfileProvider>().profile?.name ?? 'Unknown Farm';
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(imageFile: image, farmProfile: farmName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FutureBuilder<void>(
                    future: _initializeFuture,
                    builder: (context, snapshot) {
                      final controller = _controller;
                      if (controller != null &&
                          controller.value.isInitialized) {
                        return CameraPreview(controller);
                      }
                      return const ColoredBox(
                        color: Color(0xFF101827),
                        child: Center(
                          child: Icon(LucideIcons.camera,
                              color: Colors.white24, size: 56),
                        ),
                      );
                    },
                  ),
                  Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.76,
                      heightFactor: 0.55,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54, width: 2),
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Static "Offline" status for now. Once
                        // TFLiteDetectionEngine is wired up, swap this
                        // for a live status derived from the engine's
                        // isReady/loading state (e.g. "Loading Model…"
                        // -> "Model Ready").
                        const _Pill(icon: LucideIcons.wifiOff, text: 'Offline'),
                        _RoundGlassButton(
                          icon: LucideIcons.zap,
                          active: _flashMode == FlashMode.torch,
                          onTap: _toggleFlash,
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    top: 62,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _Pill(
                          icon: LucideIcons.focus, text: 'Hold 15–30cm away'),
                    ),
                  ),
                  const Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _Pill(
                          icon: LucideIcons.sun,
                          text: 'Avoid direct flash / sunlight glare'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GalleryButton(onTap: _busy ? null : _pickFromGallery),
                  GestureDetector(
                    onTap: _busy ? null : _capture,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white24, width: 4),
                      ),
                      child: _busy
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.navy),
                            )
                          : null,
                    ),
                  ),
                  // Balances the gallery button so the shutter stays
                  // visually centered.
                  const SizedBox(width: 54),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundGlassButton extends StatelessWidget {
  const _RoundGlassButton(
      {required this.icon, this.onTap, this.active = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active
              ? AppColors.amber.withOpacity(0.9)
              : Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: const Icon(LucideIcons.image, color: Colors.white, size: 22),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
