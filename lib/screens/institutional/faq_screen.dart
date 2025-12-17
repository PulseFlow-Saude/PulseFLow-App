import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/institutional_page.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InstitutionalPage(
      title: 'inst_faq_title'.tr,
      subtitle: 'inst_faq_subtitle'.tr,
      icon: Icons.help_outline,
      children: [
        _FaqItem(
          question: 'inst_faq_q1'.tr,
          answer: 'inst_faq_a1'.tr,
        ),
        _FaqItem(
          question: 'inst_faq_q2'.tr,
          answer: 'inst_faq_a2'.tr,
        ),
        _FaqItem(
          question: 'inst_faq_q3'.tr,
          answer: 'inst_faq_a3'.tr,
        ),
        _FaqItem(
          question: 'inst_faq_q4'.tr,
          answer: 'inst_faq_a4'.tr,
        ),
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
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

