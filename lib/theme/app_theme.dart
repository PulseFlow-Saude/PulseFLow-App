import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tipografia só com [TextStyle] — evita [GoogleFonts] no primeiro layout (custoso até cache).
class AppTheme {
  // Cores principais
  static const Color primaryBlue = Color(0xFF00324A); // Azul principal
  static const Color secondaryBlue = Color(0xFF64B5F6); // Azul secundário
  static const Color lightBlue = Color(0xFFE3F2FD); // Azul claro para fundos
  static const Color darkBlue = Color(0xFF00324A); // Azul escuro para hover/press

  // Cores de texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);

  // Cores de status
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);

  static TextStyle get headlineSmall => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get titleLarge => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get titleMedium => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.25,
      );

  static TextStyle get titleSmall => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.15,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        color: textPrimary,
        letterSpacing: 0.15,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        color: textSecondary,
        letterSpacing: 0.25,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: 12,
        color: textSecondary,
        letterSpacing: 0.4,
      );

  // Estilos de botões
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: textLight,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  static final ButtonStyle secondaryButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryBlue,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  // Estilo de campos de texto
  static InputDecoration textFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: bodyMedium.copyWith(color: textSecondary),
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: secondaryBlue),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: secondaryBlue),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: error),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  // Gradiente de fundo
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE3F2FD),
      Color(0xFFBBDEFB),
    ],
  );

  /// Hora, bateria e ícones da status bar em **branco/claro** (iPhone e Android).
  ///
  /// iOS: [statusBarBrightness] `Brightness.dark` corresponde a conteúdo **claro** na barra de estado.
  /// Usar com [AnnotatedRegion] na raiz do app e com [AppBarTheme.systemOverlayStyle].
  static final SystemUiOverlayStyle lightStatusBarOverlay =
      SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: primaryBlue,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  /// Nome legado — mesmo que [lightStatusBarOverlay].
  static SystemUiOverlayStyle get blueSystemOverlayStyle => lightStatusBarOverlay;

  /// Mesmo gradiente da área superior da home (telas com topo azul).
  static BoxDecoration get blueScreenGradientDecoration => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue,
            const Color(0xFF001F2E),
            primaryBlue.withValues(alpha: 0.92),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      );

  /// Painel branco inferior com cantos superiores arredondados (como o sheet da home).
  static BoxDecoration get blueContentSheetDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      );

  /// Cartões em listas sobre fundo branco (home, menu, etc.).
  static BoxDecoration surfaceListCardDecoration({bool emphasized = false}) {
    return BoxDecoration(
      color: const Color(0xFFF8FAFB),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: emphasized
            ? primaryBlue.withValues(alpha: 0.32)
            : primaryBlue.withValues(alpha: 0.12),
        width: emphasized ? 1.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.07),
          blurRadius: 22,
          offset: const Offset(0, 7),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
} 