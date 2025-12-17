import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/institutional_page.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final SettingsController controller = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return InstitutionalPage(
      title: 'inst_settings_title'.tr,
      subtitle: 'inst_settings_subtitle'.tr,
      icon: Icons.tune,
      children: [
        _SettingsSection(
          title: 'inst_settings_section_notifications'.tr,
          children: [
            Obx(() => _ToggleCard(
                  label: 'inst_settings_alerts_label'.tr,
                  description: 'inst_settings_alerts_desc'.tr,
                  icon: Icons.warning_amber_outlined,
                  value: controller.criticalAlerts.value,
                  onChanged: controller.toggleCriticalAlerts,
                )),
            Obx(() => _ToggleCard(
                  label: 'inst_settings_daily_label'.tr,
                  description: 'inst_settings_daily_desc'.tr,
                  icon: Icons.today_outlined,
                  value: controller.dailySummary.value,
                  onChanged: controller.toggleDailySummary,
                )),
            Obx(() => _ToggleCard(
                  label: 'inst_settings_smart_label'.tr,
                  description: 'inst_settings_smart_desc'.tr,
                  icon: Icons.notifications_active_outlined,
                  value: controller.smartReminders.value,
                  onChanged: controller.toggleSmartReminders,
                )),
          ],
        ),
        _SettingsSection(
          title: 'inst_settings_section_privacy'.tr,
          children: [
            Obx(() => _ToggleCard(
                  label: 'inst_settings_visibility_label'.tr,
                  description: 'inst_settings_visibility_desc'.tr,
                  icon: Icons.visibility_outlined,
                  value: controller.dataVisibility.value,
                  onChanged: controller.toggleDataVisibility,
                )),
            Obx(() => _ToggleCard(
                  label: 'inst_settings_access_label'.tr,
                  description: 'inst_settings_access_desc'.tr,
                  icon: Icons.mail_outline,
                  value: controller.accessLogsEmail.value,
                  onChanged: controller.toggleAccessLogsEmail,
                )),
          ],
        ),
        _SettingsSection(
          title: 'inst_settings_section_experience'.tr,
          children: [
            Obx(() => _ToggleCard(
                  label: 'inst_settings_theme_label'.tr,
                  description: 'inst_settings_theme_desc'.tr,
                  icon: Icons.dark_mode_outlined,
                  value: controller.darkTheme.value,
                  onChanged: controller.toggleDarkTheme,
                )),
            Obx(() => _DropdownCard(
                  label: 'inst_settings_language_label'.tr,
                  description: 'inst_settings_language_desc'.tr,
                  icon: Icons.language_outlined,
                  value: controller.language.value,
                  items: [
                    DropdownMenuItem(value: 'pt_BR', child: Text('inst_settings_language_pt'.tr)),
                    DropdownMenuItem(value: 'en_US', child: Text('inst_settings_language_en'.tr)),
                  ],
                  onChanged: controller.changeLanguage,
                )),
          ],
        ),
        _SettingsSection(
          title: 'inst_settings_section_account'.tr,
          children: [
            Obx(() => _DangerCard(
                  label: 'inst_settings_delete_label'.tr,
                  description: 'inst_settings_delete_desc'.tr,
                  icon: Icons.delete_outline,
                  buttonLabel: controller.isDeletingAccount.value
                      ? 'inst_settings_delete_loading'.tr
                      : 'inst_settings_delete_button'.tr,
                  isLoading: controller.isDeletingAccount.value,
                  onPressed: () => _confirmDeleteAccount(context),
                )),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'inst_settings_delete_confirm_title'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('inst_settings_delete_confirm_desc'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('inst_settings_delete_confirm_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('inst_settings_delete_confirm_action'.tr),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await controller.deleteAccount();
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00324A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF00324A)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0F172A),
          ),
        ],
      ),
    );
  }
}

class _DropdownCard extends StatelessWidget {
  const _DropdownCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String description;
  final IconData icon;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00324A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF00324A)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: value,
                  items: items,
                  underline: const SizedBox.shrink(),
                  onChanged: (selected) {
                    if (selected != null) {
                      onChanged(selected);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerCard extends StatelessWidget {
  const _DangerCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.buttonLabel,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final String description;
  final IconData icon;
  final String buttonLabel;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.red.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            buttonLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
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

