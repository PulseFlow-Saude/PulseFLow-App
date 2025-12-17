import 'package:flutter/material.dart';

class HormonalIcon extends StatelessWidget {
  final double size;
  final Color color;
  const HormonalIcon({super.key, this.size = 40, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HormonalPainter(color),
      ),
    );
  }
}

class _HormonalPainter extends CustomPainter {
  final Color color;
  _HormonalPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..color = color;

    final w = size.width;
    final h = size.height;

    // Frasco (beaker)
    final path = Path()
      ..moveTo(w * 0.30, h * 0.15)
      ..lineTo(w * 0.70, h * 0.15)
      ..lineTo(w * 0.62, h * 0.35)
      ..quadraticBezierTo(w * 0.60, h * 0.40, w * 0.58, h * 0.45)
      ..lineTo(w * 0.58, h * 0.78)
      ..quadraticBezierTo(w * 0.58, h * 0.88, w * 0.50, h * 0.88)
      ..lineTo(w * 0.50, h * 0.88)
      ..quadraticBezierTo(w * 0.42, h * 0.88, w * 0.42, h * 0.78)
      ..lineTo(w * 0.42, h * 0.45)
      ..quadraticBezierTo(w * 0.40, h * 0.40, w * 0.38, h * 0.35)
      ..close();
    canvas.drawPath(path, stroke);

    // Hormônio (círculos interligados tipo molécula)
    final molecule = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..color = color;
    final c1 = Offset(w * 0.25, h * 0.55);
    final c2 = Offset(w * 0.18, h * 0.35);
    final c3 = Offset(w * 0.12, h * 0.60);
    canvas.drawCircle(c1, w * 0.08, molecule);
    canvas.drawCircle(c2, w * 0.06, molecule);
    canvas.drawCircle(c3, w * 0.05, molecule);
    canvas.drawLine(c1, c2, molecule);
    canvas.drawLine(c1, c3, molecule);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


