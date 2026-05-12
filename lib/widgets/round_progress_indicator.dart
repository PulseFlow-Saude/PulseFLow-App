import 'package:flutter/material.dart';

/// O [CircularProgressIndicator] assume ~36×36; dentro de [ElevatedButton.icon] ou
/// [Row] com restrições assimétricas fica oval. Este widget encaixa-o num quadrado
/// com escala uniforme.
class RoundProgressIndicator extends StatelessWidget {
  const RoundProgressIndicator({
    super.key,
    this.dimension = 24,
    this.strokeWidth = 3,
    this.color = Colors.white,
  });

  final double dimension;
  final double strokeWidth;
  final Color color;

  static const double _design = 36;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: dimension,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox.square(
          dimension: _design,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
    );
  }
}
