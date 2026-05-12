import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ícone promocional: animação estilo Face ID e transição (flip 3D) para impressão digital no mesmo lugar.
class AnimatedFaceFingerprintIcon extends StatefulWidget {
  const AnimatedFaceFingerprintIcon({
    super.key,
    required this.color,
    this.size = 52,
  });

  final Color color;
  final double size;

  @override
  State<AnimatedFaceFingerprintIcon> createState() =>
      _AnimatedFaceFingerprintIconState();
}

class _AnimatedFaceFingerprintIconState extends State<AnimatedFaceFingerprintIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  /// 0–[a]: rotação 0→π (face→dedo); [a]–[b]: segura no dedo; [b]–[c]: π→2π (dedo→face); resto: segura na face.
  static const _tToFingerEnd = 0.40;
  static const _tHoldFinger = 0.68;
  static const _tToFaceEnd = 0.94;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _angleFor(double t) {
    if (t <= _tToFingerEnd) {
      return math.pi * Curves.easeInOutCubic.transform(t / _tToFingerEnd);
    }
    if (t <= _tHoldFinger) {
      return math.pi;
    }
    if (t <= _tToFaceEnd) {
      final u = (t - _tHoldFinger) / (_tToFaceEnd - _tHoldFinger);
      return math.pi + math.pi * Curves.easeInOutCubic.transform(u);
    }
    return 2 * math.pi;
  }

  /// Fase interna da face (scan) e do dedo (pulso) em 0..1 dentro do segmento visível.
  double _faceScanPhase(double t) {
    if (t <= _tToFingerEnd) {
      return Curves.easeInOut.transform(t / _tToFingerEnd);
    }
    if (t >= _tToFaceEnd) {
      return Curves.easeInOut.transform((t - _tToFaceEnd) / (1.0 - _tToFaceEnd));
    }
    return 1;
  }

  double _fingerPulsePhase(double t) {
    if (t < _tToFingerEnd) return 0;
    if (t > _tHoldFinger) return 1;
    return Curves.easeInOut.transform((t - _tToFingerEnd) / (_tHoldFinger - _tToFingerEnd));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final angle = _angleFor(t);
        final showFace = math.cos(angle) >= 0;
        final faceScan = _faceScanPhase(t);
        final fingerPulse = _fingerPulsePhase(t);

        return SizedBox(
          width: s,
          height: s,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..rotateY(angle),
            child: showFace
                ? _FaceIdMark(
                    color: widget.color,
                    size: s,
                    scanProgress: faceScan,
                  )
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: _FingerprintMark(
                      color: widget.color,
                      size: s,
                      pulse: fingerPulse,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

/// Silhueta tipo “Face ID” com linha de varredura.
class _FaceIdMark extends StatelessWidget {
  const _FaceIdMark({
    required this.color,
    required this.size,
    required this.scanProgress,
  });

  final Color color;
  final double size;
  final double scanProgress;

  @override
  Widget build(BuildContext context) {
    final w = size * 0.62;
    final h = size * 0.78;
    return CustomPaint(
      size: Size(size, size),
      painter: _FaceIdPainter(
        color: color,
        rectW: w,
        rectH: h,
        scanProgress: scanProgress,
      ),
    );
  }
}

class _FaceIdPainter extends CustomPainter {
  _FaceIdPainter({
    required this.color,
    required this.rectW,
    required this.rectH,
    required this.scanProgress,
  });

  final Color color;
  final double rectW;
  final double rectH;
  final double scanProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: rectW, height: rectH),
      Radius.circular(rectW * 0.22),
    );

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, size.shortestSide * 0.045)
      ..color = color.withValues(alpha: 0.92);

    canvas.drawRRect(rrect, border);

    final face = Paint()..color = color.withValues(alpha: 0.88);
    final eyeR = math.max(2.2, size.shortestSide * 0.035);
    canvas.drawCircle(Offset(cx - rectW * 0.16, cy - rectH * 0.06), eyeR, face);
    canvas.drawCircle(Offset(cx + rectW * 0.16, cy - rectH * 0.06), eyeR, face);

    final smile = Path()
      ..addArc(
        Rect.fromCenter(
          center: Offset(cx, cy + rectH * 0.06),
          width: rectW * 0.38,
          height: rectH * 0.22,
        ),
        math.pi * 0.08,
        math.pi * 0.84,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.0, size.shortestSide * 0.038)
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.88),
    );

    final bounds = rrect.outerRect;
    final scanY = bounds.top + 6 + (bounds.height - 12) * scanProgress;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.0, size.shortestSide * 0.05)
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, size.shortestSide * 0.034)
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.75);

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawLine(Offset(bounds.left + 4, scanY), Offset(bounds.right - 4, scanY), glow);
    canvas.drawLine(Offset(bounds.left + 4, scanY), Offset(bounds.right - 4, scanY), line);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FaceIdPainter oldDelegate) =>
      oldDelegate.scanProgress != scanProgress ||
      oldDelegate.color != color;
}

class _FingerprintMark extends StatelessWidget {
  const _FingerprintMark({
    required this.color,
    required this.size,
    required this.pulse,
  });

  final Color color;
  final double size;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final scale = 0.96 + 0.04 * math.sin(pulse * math.pi * 4);
    return Transform.scale(
      scale: scale,
      child: Icon(
        Icons.fingerprint_rounded,
        size: size,
        color: color.withValues(
          alpha: (0.88 + 0.1 * (0.5 + 0.5 * math.sin(pulse * math.pi * 4))).clamp(0.0, 1.0),
        ),
      ),
    );
  }
}
