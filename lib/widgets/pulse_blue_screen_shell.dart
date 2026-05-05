import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'pulse_drawer_button.dart';

/// Tipografia branca para títulos no topo azul (alinhado à home).
class PulseBlueHeaderStyles {
  PulseBlueHeaderStyles._();

  static TextStyle get title => AppTheme.titleLarge.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 22,
        height: 1.2,
      );

  static TextStyle get subtitle => AppTheme.bodyMedium.copyWith(
        color: Colors.white.withValues(alpha: 0.78),
        height: 1.35,
        fontSize: 14,
      );

  static TextStyle get titleCompact => AppTheme.titleMedium.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
        height: 1.2,
      );

  static TextStyle get subtitleCompact => AppTheme.bodyMedium.copyWith(
        color: Colors.white.withValues(alpha: 0.75),
        fontSize: 13,
        height: 1.35,
      );
}

/// Menu lateral + título centrado (substitui AppBar centralizada das telas de registros).
class PulseBlueCenteredTitleHeader extends StatelessWidget {
  const PulseBlueCenteredTitleHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: PulseDrawerButton(iconSize: 22),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Text(
                title,
                style: PulseBlueHeaderStyles.titleCompact,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menu lateral + título/subtítulo à esquerda e opcional [trailing] (ex.: ícone de ação).
class PulseBlueLeadTitleHeader extends StatelessWidget {
  const PulseBlueLeadTitleHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.drawerIconSize = 22,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double drawerIconSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PulseDrawerButton(iconSize: drawerIconSize),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PulseBlueHeaderStyles.title),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!, style: PulseBlueHeaderStyles.subtitle),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Layout: gradiente azul + [header] + painel branco arredondado com [body].
class PulseBlueScaffold extends StatelessWidget {
  const PulseBlueScaffold({
    super.key,
    required this.header,
    required this.body,
    this.drawer,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget header;
  final Widget body;
  final Widget? drawer;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.blueSystemOverlayStyle,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        drawer: drawer,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: AppTheme.blueScreenGradientDecoration,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                Expanded(
                  child: PulseBlueWhiteSheet(child: body),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PulseBlueWhiteSheet extends StatelessWidget {
  const PulseBlueWhiteSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.blueContentSheetDecoration,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
