import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/institutional/settings_controller.dart';

/// Opção de idioma: código locale, bandeira (emoji), nome nativo.
class LanguageOption {
  const LanguageOption({
    required this.localeCode,
    required this.flag,
    required this.name,
  });
  final String localeCode;
  final String flag;
  final String name;
}

/// Lista de idiomas no seletor (apenas Português e Inglês).
const List<LanguageOption> kLanguageOptions = [
  LanguageOption(localeCode: 'pt_BR', flag: '🇧🇷', name: 'Português'),
  LanguageOption(localeCode: 'en_US', flag: '🇺🇸', name: 'English'),
];

/// Ícone para o canto superior (AppBar) que abre o seletor de idioma em grid.
class LanguageIconButton extends StatelessWidget {
  const LanguageIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.language_rounded, color: Colors.white, size: 24),
      tooltip: 'Idioma',
      onPressed: () => LanguageIconButton.showLanguageModal(context),
    );
  }

  /// Abre o modal de seleção de idioma (pode ser chamado pelo ícone ou pela tela de configurações).
  static void showLanguageModal(BuildContext context) {
    final settings = Get.find<SettingsController>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho com título e botão fechar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00324A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: Color(0xFF00324A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Idioma / Language',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Grid de idiomas
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  final current = settings.language.value;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kLanguageOptions.map((opt) {
                      final selected = current == opt.localeCode;
                      return _LanguageChip(
                        flag: opt.flag,
                        name: opt.name,
                        selected: selected,
                        onTap: () async {
                          await settings.changeLanguage(opt.localeCode);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      );
                    }).toList(),
                  );
                }),
              ),
            ),
            const SafeArea(child: SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }
}

double _chipWidth(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  const padding = 32.0;
  const spacing = 10.0;
  const count = 3;
  return (w - padding - spacing * (count - 1)) / count;
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.flag,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _chipWidth(context),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF00324A).withOpacity(0.08)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFF00324A) : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? const Color(0xFF00324A) : Colors.grey.shade800,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 4),
                const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF00324A)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
