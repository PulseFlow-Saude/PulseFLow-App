import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/institutional_page.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InstitutionalPage(
      title: 'inst_about_title'.tr,
      subtitle: 'inst_about_subtitle'.tr,
      icon: Icons.favorite_outline,
      children: [
        _IntroText(text: 'inst_about_intro'.tr),
        _InfoTile(
          title: 'inst_about_approach'.tr,
          description: 'inst_about_approach_desc'.tr,
        ),
        _InfoTile(
          title: 'inst_about_team'.tr,
          description: 'inst_about_team_desc'.tr,
        ),
        _InfoTile(
          title: 'inst_about_vision'.tr,
          description: 'inst_about_vision_desc'.tr,
        ),
      ],
    );
  }
}

class _IntroText extends StatelessWidget {
  const _IntroText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        height: 1.5,
        fontSize: 15,
        color: Colors.grey[700],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
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

