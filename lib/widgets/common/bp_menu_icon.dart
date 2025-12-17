import 'package:flutter/material.dart';

class BpMenuIcon extends StatelessWidget {
  final double size;
  final Color color;

  const BpMenuIcon({super.key, this.size = 40, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Gauge base
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.speed, size: size * 0.85, color: color),
          ),
          // Small heart overlay (represents cardio/pressure)
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(Icons.favorite, size: size * 0.40, color: color.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}


