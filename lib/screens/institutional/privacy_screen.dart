import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/institutional_page.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InstitutionalPage(
      title: 'inst_privacy_title'.tr,
      subtitle: 'inst_privacy_subtitle'.tr,
      icon: Icons.privacy_tip_outlined,
      children: [
        _PrivacySection(
          title: 'inst_privacy_collect'.tr,
          description: 'inst_privacy_collect_desc'.tr,
        ),
        _PrivacySection(
          title: 'inst_privacy_share'.tr,
          description: 'inst_privacy_share_desc'.tr,
        ),
        _PrivacySection(
          title: 'inst_privacy_store'.tr,
          description: 'inst_privacy_store_desc'.tr,
        ),
        _PrivacySection(
          title: 'inst_privacy_rights'.tr,
          description: 'inst_privacy_rights_desc'.tr,
        ),
      ],
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
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
    );
  }
}

