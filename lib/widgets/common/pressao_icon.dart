import 'package:flutter/material.dart';

class PressaoIcon extends StatelessWidget {
  final double size;
  final Color color;

  const PressaoIcon({super.key, this.size = 40, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PressaoIconPainter(color),
      ),
    );
  }
}

class _PressaoIconPainter extends CustomPainter {
  final Color color;
  _PressaoIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final w = size.width;
    final h = size.height;

    // Cuff (rounded rectangle)
    final cuffRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.18, w * 0.45, h * 0.42),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(cuffRect, stroke);

    // Gauge (circle) overlapping the cuff
    final gaugeCenter = Offset(w * 0.48, h * 0.52);
    final gaugeRadius = w * 0.20;
    canvas.drawCircle(gaugeCenter, gaugeRadius, stroke);
    // Needle (simple tick)
    canvas.drawLine(
      gaugeCenter,
      Offset(gaugeCenter.dx, gaugeCenter.dy - gaugeRadius * 0.45),
      stroke,
    );

    // Bulb (ellipse) on the right
    final bulbRect = Rect.fromCenter(
      center: Offset(w * 0.82, h * 0.28),
      width: w * 0.22,
      height: h * 0.30,
    );
    canvas.drawOval(bulbRect, stroke);

    // Hose connecting gauge to bulb
    final hose = Path()
      ..moveTo(gaugeCenter.dx, gaugeCenter.dy + gaugeRadius)
      ..quadraticBezierTo(w * 0.70, h * 0.88, bulbRect.center.dx, bulbRect.bottom);
    canvas.drawPath(hose, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


