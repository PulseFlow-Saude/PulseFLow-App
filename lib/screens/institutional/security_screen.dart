import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/institutional_page.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InstitutionalPage(
      title: 'inst_security_title'.tr,
      subtitle: 'inst_security_subtitle'.tr,
      icon: Icons.shield_outlined,
      children: [
        _SecurityCard(
          title: 'inst_security_card1'.tr,
          description: 'inst_security_card1_desc'.tr,
          icon: Icons.lock_outline,
        ),
        _SecurityCard(
          title: 'inst_security_card2'.tr,
          description: 'inst_security_card2_desc'.tr,
          icon: Icons.admin_panel_settings_outlined,
        ),
        _SecurityCard(
          title: 'inst_security_card3'.tr,
          description: 'inst_security_card3_desc'.tr,
          icon: Icons.verified_user_outlined,
        ),
        _SecurityCard(
          title: 'inst_security_card4'.tr,
          description: 'inst_security_card4_desc'.tr,
          icon: Icons.notifications_active_outlined,
        ),
      ],
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

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
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
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

