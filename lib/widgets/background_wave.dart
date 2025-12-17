import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BackgroundWave extends StatelessWidget {
  final double height;
  final Widget? child;

  const BackgroundWave({Key? key, this.height = 340, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: height,
          child: CustomPaint(
            painter: _WavePainter(),
          ),
        ),
        if (child != null)
          Positioned.fill(
            child: child!,
          ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.45,
      size.width * 0.5, size.height * 0.55,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.65,
      size.width, size.height * 0.55,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);

    // Bolhas
    final bubblePaint = Paint()..color = AppTheme.secondaryBlue.withOpacity(0.18);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.25), 32, bubblePaint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.18), 22, bubblePaint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.38), 18, bubblePaint);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.12), 14, bubblePaint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.32), 10, bubblePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 