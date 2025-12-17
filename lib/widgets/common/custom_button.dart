import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isSecondary;

  CustomButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return isSecondary
        ? TextButton(
            onPressed: onPressed,
            style: AppTheme.secondaryButtonStyle,
            child: child,
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: AppTheme.primaryButtonStyle,
            child: child,
          );
  }
} 