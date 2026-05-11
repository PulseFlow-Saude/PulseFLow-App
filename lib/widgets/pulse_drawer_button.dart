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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.menu_rounded,
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

/// Voltar com o mesmo “pill” translúcido do menu na home.
class PulseBlueBackButton extends StatelessWidget {
  const PulseBlueBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}

