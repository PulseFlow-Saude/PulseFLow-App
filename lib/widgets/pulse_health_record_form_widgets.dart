import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estilo partilhado com registo de crise / upload de exames (campos cinzentos + foco azul).
abstract final class PulseHealthRecordFormStyles {
  static const Color fillColor = Color(0xFFF8F9FA);
  static const Color sectionBorderColor = Color(0xFFE5E7EB);
  static const Color labelColor = Color(0xFF212121);

  static InputDecoration modernInputDecoration({
    required String hintText,
    double horizontalPadding = 16,
    double verticalPadding = 16,
    double hintFontSize = 15,
  }) {
    final borderGrey = Colors.grey[300]!;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: hintFontSize),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
    );
  }

  /// Tema para [DropdownMenu] alinhado aos campos modernos.
  static ThemeData dropdownTheme(BuildContext context) {
    final borderGrey = Colors.grey[300]!;
    return Theme.of(context).copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

/// Cartão cinza no topo do formulário (como crise / exames).
class PulseRecordSectionIntro extends StatelessWidget {
  const PulseRecordSectionIntro({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final pad = narrow ? 16.0 : 20.0;
    final iconPad = narrow ? 10.0 : 12.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: PulseHealthRecordFormStyles.fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PulseHealthRecordFormStyles.sectionBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(iconPad),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: narrow ? 22 : 24),
          ),
          SizedBox(width: narrow ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: narrow ? 17 : 19,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: narrow ? 12 : 13,
                    color: AppTheme.primaryBlue.withOpacity(0.72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de label com ícone (como `_buildModernTextField` em exames).
class PulseRecordFieldLabelRow extends StatelessWidget {
  const PulseRecordFieldLabelRow({
    super.key,
    required this.icon,
    required this.label,
    this.isRequired = false,
    this.fontSize = 14,
  });

  final IconData icon;
  final String label;
  final bool isRequired;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBlue),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: PulseHealthRecordFormStyles.labelColor,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

/// Campo de data tocável (estilo upload de exames).
class PulseRecordLabeledDateTile extends StatelessWidget {
  const PulseRecordLabeledDateTile({
    super.key,
    required this.onTap,
    required this.label,
    required this.displayText,
    required this.placeholderText,
    this.labelIcon = Icons.calendar_today_outlined,
    this.isRequired = false,
    this.showTrailingChevron = true,
  });

  final VoidCallback onTap;
  final String label;
  final IconData labelIcon;
  final bool isRequired;
  final String displayText;
  final String placeholderText;
  final bool showTrailingChevron;

  bool get _hasValue => displayText != placeholderText;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final borderGrey = Colors.grey[300]!;
    final hPad = narrow ? 14.0 : 16.0;
    final vPad = narrow ? 14.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PulseRecordFieldLabelRow(icon: labelIcon, label: label, isRequired: isRequired),
        SizedBox(height: narrow ? 6 : 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              color: PulseHealthRecordFormStyles.fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderGrey),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range_outlined, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _hasValue ? displayText : placeholderText,
                    style: TextStyle(
                      fontSize: narrow ? 15 : 16,
                      color: _hasValue ? PulseHealthRecordFormStyles.labelColor : Colors.grey[400],
                    ),
                  ),
                ),
                if (showTrailingChevron)
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Margens como na [CriseGastriteFormScreen]: scroll com 20 dp nas laterais (sem segunda “caixa” a estreitar).
/// Largura útil = toda a área do painel branco (sem cap tipo 800 dp do upload de exames).
abstract final class PulseHealthRecordLayout {
  /// Usa toda a largura disponível do pai (equivalente à crise de gastrite no painel branco).
  static double contentMaxWidth(double parentMaxWidth) => parentMaxWidth;

  /// Igual à crise de gastrite (`padding: EdgeInsets.all(20)` no scroll); só o topo varia em ecrã baixo.
  static EdgeInsets scrollPadding(
    BuildContext context, {
    double bottom = 120,
  }) {
    final screenSize = MediaQuery.sizeOf(context);
    final isSmallScreen = screenSize.height < 700;
    return EdgeInsets.only(
      left: 20,
      right: 20,
      top: isSmallScreen ? 16 : 20,
      bottom: bottom,
    );
  }
}

/// Garante alinhamento ao topo; a largura segue o pai (sem forçar `SizedBox` estreito).
class PulseHealthRecordMaxWidthAlign extends StatelessWidget {
  const PulseHealthRecordMaxWidthAlign({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = PulseHealthRecordLayout.contentMaxWidth(constraints.maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
