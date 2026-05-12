import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/auth_service.dart';
import '../../../services/biometric_login_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/animated_face_fingerprint_icon.dart';
import '../../../widgets/round_progress_indicator.dart';
import '../../institutional/settings_controller.dart';

/// Oferta única (primeiro login com 2FA neste dispositivo) para ativar acesso por biometria.
class BiometricFirstLoginSheet extends StatefulWidget {
  const BiometricFirstLoginSheet({
    super.key,
    required this.email,
    required this.password,
    required this.onFinished,
  });

  final String email;
  final String password;
  final VoidCallback onFinished;

  @override
  State<BiometricFirstLoginSheet> createState() => _BiometricFirstLoginSheetState();
}

class _BiometricFirstLoginSheetState extends State<BiometricFirstLoginSheet>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _shimmer;
  late final Animation<double> _pulseScale;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
    _pulseScale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _decline() async {
    await AuthService.instance.markBiometricFirstLoginPromptShown();
    if (!mounted) return;
    widget.onFinished();
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final supported = await BiometricLoginService.instance.isDeviceSupported;
      if (!supported) {
        Get.snackbar(
          'auth_biometric_unavailable_title'.tr,
          'auth_biometric_unavailable_body'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
        );
        await _decline();
        return;
      }
      final ok = await BiometricLoginService.instance.authenticate(
        localizedReason: 'auth_biometric_reason_enable'.tr,
      );
      if (!ok) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      await AuthService.instance.enableBiometricStoredCredentials(
        widget.email,
        widget.password,
      );
      await AuthService.instance.markBiometricFirstLoginPromptShown();
      if (Get.isRegistered<SettingsController>()) {
        await Get.find<SettingsController>().refreshBiometricLoginFlag();
      }
      if (!mounted) return;
      Get.snackbar(
        'auth_biometric_enabled_title'.tr,
        'auth_biometric_enabled_body'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      );
      widget.onFinished();
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      Get.snackbar(
        'auth_error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFEFF6FF),
                  Colors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shimmer,
                    builder: (context, _) {
                      final t = _shimmer.value * 2 * math.pi;
                      return CustomPaint(
                        painter: _SoftGlowPainter(phase: t),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _pulseScale,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primaryBlue.withValues(alpha: 0.2),
                                AppTheme.primaryBlue.withValues(alpha: 0.05),
                              ],
                            ),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                              width: 2,
                            ),
                          ),
                          child: AnimatedFaceFingerprintIcon(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.95),
                            size: 52,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'auth_biometric_offer_title'.tr,
                        textAlign: TextAlign.center,
                        style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'auth_biometric_offer_subtitle'.tr,
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _busy ? null : _decline,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.45),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'auth_biometric_offer_later'.tr,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryBlue,
                                    AppTheme.primaryBlue.withValues(alpha: 0.88),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _busy ? null : _accept,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _busy
                                    ? const RoundProgressIndicator(
                                        dimension: 22,
                                        strokeWidth: 2.8,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        'auth_biometric_offer_activate'.tr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftGlowPainter extends CustomPainter {
  _SoftGlowPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 3; i++) {
      final dx = size.width * (0.35 + 0.15 * math.sin(phase + i * 0.9));
      final dy = size.height * (0.25 + 0.12 * math.cos(phase * 0.8 + i));
      paint.shader = RadialGradient(
        colors: [
          AppTheme.primaryBlue.withValues(alpha: 0.07 - i * 0.015),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: size.shortestSide * 0.55));
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoftGlowPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
