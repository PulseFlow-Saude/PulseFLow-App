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
              'assets/images/pulseflow2.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
            SizedBox(height: spacing),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
              child: Text(
                'Termos de Uso',
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
                'PulseFlow - Plataforma de Saúde Digital',
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
                    'Termos de Uso e Privacidade',
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
          title: '1. Sobre o PulseFlow',
          content: 'O PulseFlow é uma plataforma digital focada na área da saúde, desenvolvida para facilitar a interação segura entre médicos e pacientes. Nossa aplicação oferece funcionalidades como autenticação em dois fatores, visualização de prontuários médicos, anexos de exames e comunicação protegida entre profissionais da saúde e seus pacientes.',
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: '2. Aceitação dos Termos',
          content: 'Ao utilizar o PulseFlow, você concorda em cumprir e estar vinculado a estes Termos de Uso. Se você não concordar com qualquer parte destes termos, não deve utilizar nossa plataforma.',
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: '3. Uso da Plataforma',
          content: 'O PulseFlow destina-se exclusivamente a fins médicos e de saúde. Os usuários devem:\n\n• Fornecer informações verdadeiras e precisas\n• Manter a confidencialidade de suas credenciais de acesso\n• Utilizar a plataforma de forma ética e responsável\n• Respeitar a privacidade de outros usuários\n• Não compartilhar informações médicas sem autorização',
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: '4. Proteção de Dados',
          content: 'Comprometemo-nos a proteger seus dados pessoais e informações médicas de acordo com a Lei Geral de Proteção de Dados (LGPD) e as melhores práticas de segurança. Implementamos medidas técnicas e organizacionais para garantir a segurança e confidencialidade de suas informações.',
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: '5. Responsabilidades do Usuário',
          content: 'Você é responsável por:\n\n• Manter a segurança de sua conta e senha\n• Informar-nos imediatamente sobre qualquer uso não autorizado\n• Usar a plataforma apenas para fins legítimos\n• Não tentar acessar sistemas ou dados de outros usuários\n• Cumprir todas as leis e regulamentações aplicáveis',
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: '6. Limitação de Responsabilidade',
          content: 'O PulseFlow é fornecido "como está". Não garantimos que a plataforma estará sempre disponível ou livre de erros. Nossa responsabilidade é limitada ao máximo permitido por lei.',
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: '7. Modificações',
          content: 'Reservamo-nos o direito de modificar estes termos a qualquer momento. As alterações entrarão em vigor imediatamente após a publicação. O uso continuado da plataforma constitui aceitação dos novos termos.',
          size: size,
        ),
        
        SizedBox(height: size.height * 0.02),
        _buildSection(
          title: '8. Contato',
          content: 'Para dúvidas sobre estes termos ou sobre o PulseFlow, entre em contato conosco através dos canais oficiais da plataforma.',
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
                'Entendi os Termos',
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