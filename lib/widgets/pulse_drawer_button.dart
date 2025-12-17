import 'package:flutter/material.dart';

class PulseDrawerButton extends StatelessWidget {
  const PulseDrawerButton({super.key, this.iconSize = 24});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return IconButton(
          iconSize: iconSize,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.menu,
              color: Colors.white,
              size: iconSize,
            ),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        );
      },
    );
  }
}

