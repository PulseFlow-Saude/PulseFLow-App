import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00324A),
              const Color(0xFF00324A).withValues(alpha: 0.85),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildContent(isLandscape, size),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isLandscape, Size size) {
    if (isLandscape) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildLogoSection(size),
          ),
          Expanded(
            flex: 1,
            child: _buildFormSection(size),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            flex: 1,
            child: _buildLogoSection(size),
          ),
          Expanded(
            flex: 5,
            child: _buildFormSection(size),
          ),
        ],
      );
    }
  }

  Widget _buildLogoSection(Size size) {
    final availableHeight = size.height * 0.3; // Altura aproximada disponível para o logo
    final isSmallHeight = size.height < 700;
    final logoSize = isSmallHeight 
      ? (size.width * 0.25).clamp(60.0, 100.0)
      : (size.width * 0.35).clamp(80.0, 140.0);
    final spacing = isSmallHeight ? 4.0 : size.height * 0.015;
    
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/oryon_health_logo_signin.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
            SizedBox(height: spacing),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
              child: Text(
                'terms_title'.tr,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: (size.width * 0.05).clamp(18.0, 28.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.visible,
              ),
            ),
            SizedBox(height: spacing * 0.5),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
              child: Text(
                'terms_subtitle'.tr,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: (size.width * 0.03).clamp(11.0, 15.0),
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(Size size) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints.expand(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: size.height * 0.02,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: const Color(0xFF00324A),
                    size: size.width * 0.05,
                  ),
                ),
                Expanded(
                  child: Text(
                    'terms_header'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (size.width * 0.055).clamp(20.0, 28.0),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00324A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: size.width * 0.12),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.08,
                vertical: size.height * 0.02,
              ),
              child: _buildTermsContent(size),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTermsContent(Size size) {
    final isSmallScreen = size.width < 400;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          title: 'terms_s1_title'.tr,
          content: 'terms_s1_content'.tr,
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: 'terms_s2_title'.tr,
          content: 'terms_s2_content'.tr,
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: 'terms_s3_title'.tr,
          content: 'terms_s3_content'.tr,
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: 'terms_s4_title'.tr,
          content: 'terms_s4_content'.tr,
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: 'terms_s5_title'.tr,
          content: 'terms_s5_content'.tr,
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: 'terms_s6_title'.tr,
          content: 'terms_s6_content'.tr,
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: 'terms_s7_title'.tr,
          content: 'terms_s7_content'.tr,
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: 'terms_s8_title'.tr,
          content: 'terms_s8_content'.tr,
          size: size,
        ),
        
        SizedBox(height: size.height * 0.03),
        
        _buildAcceptButton(size),
        
        SizedBox(height: size.height * 0.03),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Size size,
  }) {
    final isSmallScreen = size.width < 400;
    final padding = isSmallScreen ? 12.0 : 16.0;
    final titleSize = isSmallScreen ? size.width * 0.038 : size.width * 0.042;
    final contentSize = isSmallScreen ? size.width * 0.032 : size.width * 0.035;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00324A).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize.clamp(16.0, 22.0),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00324A),
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: size.height * 0.015),
          Text(
            content,
            style: TextStyle(
              fontSize: contentSize.clamp(13.0, 17.0),
              color: Colors.grey[700],
              height: 1.6,
              letterSpacing: 0.2,
            ),
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(Size size) {
    final isSmallScreen = size.width < 400;
    final buttonHeight = isSmallScreen ? size.height * 0.065 : size.height * 0.07;
    final fontSize = isSmallScreen ? size.width * 0.035 : size.width * 0.04;
    final iconSize = isSmallScreen ? size.width * 0.045 : size.width * 0.05;
    
    return Container(
      width: double.infinity,
      height: buttonHeight.clamp(48.0, 60.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00324A),
            const Color(0xFF00324A).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00324A).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: iconSize.clamp(18.0, 24.0),
            ),
            SizedBox(width: size.width * 0.02),
            Flexible(
              child: Text(
                'terms_btn_accept'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize.clamp(14.0, 18.0),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 