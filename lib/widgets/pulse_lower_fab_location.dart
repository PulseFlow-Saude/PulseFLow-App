import 'package:flutter/material.dart';

/// Mesmo âncora que [FloatingActionButtonLocation.endFloat], com deslocamento
/// extra para baixo no eixo Y (útil com FAB extended sobre listas/calendários).
class PulseLowerEndFloatFabLocation extends FloatingActionButtonLocation {
  const PulseLowerEndFloatFabLocation({this.extraDown = 18});

  final double extraDown;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    return FloatingActionButtonLocation.endFloat
        .getOffset(scaffoldGeometry)
        .translate(0, extraDown);
  }

  @override
  String toString() => 'PulseLowerEndFloatFabLocation(extraDown: $extraDown)';
}
