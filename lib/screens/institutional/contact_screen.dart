import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/institutional_page.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InstitutionalPage(
      title: 'inst_contact_title'.tr,
      subtitle: 'inst_contact_subtitle'.tr,
      icon: Icons.support_agent_outlined,
      children: [
        _ContactCard(
          title: 'inst_contact_support'.tr,
          value: 'pulseflowsaude@gmail.com',
          subtitle: 'inst_contact_support_desc'.tr,
          icon: Icons.email_outlined,
        ),
        _ContactCard(
          title: 'inst_contact_whatsapp'.tr,
          value: '+55 (11) 99999-0000',
          subtitle: 'inst_contact_whatsapp_desc'.tr,
          icon: Icons.chat_bubble_outline,
        ),
        _ContactCard(
          title: 'inst_contact_phone'.tr,
          value: '0800 800 2025',
          subtitle: 'inst_contact_phone_desc'.tr,
          icon: Icons.call_outlined,
        ),
        _ContactCard(
          title: 'inst_contact_address'.tr,
          value:
              'Rua Professor Dr. Euryclides de Jesus Zerbini, 1516\nParque das Universidades, Campinas - SP, 13087-571',
          subtitle: 'inst_contact_address_desc'.tr,
          icon: Icons.location_on_outlined,
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
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
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
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

