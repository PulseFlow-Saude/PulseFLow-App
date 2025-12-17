import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import 'profile_controller.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';
import '../home/home_controller.dart';
import '../../utils/greeting_utils.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.blueSystemOverlayStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFF00324A), // Cor de fundo azul para ocupar toda a tela
        drawer: const PulseSideMenu(activeItem: PulseNavItem.profile),
        body: Column(
          children: [
            // Header com perfil - sem SafeArea para ocupar toda a área superior
            _buildHeader(controller),
            
            // Conteúdo principal
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Obx(() {
                  if (controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00324A)),
                      ),
                    );
                  }
                  
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seção da foto do perfil
                        _buildProfilePhotoSection(controller),
                        const SizedBox(height: 20),
                        
                        // Seção de dados pessoais
                        _buildPersonalDataSection(controller),
                        const SizedBox(height: 20),
                        
                        // Seção de dados de saúde
                        _buildHealthDataSection(controller),
                        const SizedBox(height: 20),
                        
                        // Seção de privacidade e segurança
                        _buildPrivacySection(),
                        const SizedBox(height: 20),
                        
                        // Botão de salvar
                        _buildSaveButton(controller),
                        const SizedBox(height: 20),
                        
                        // Botão de sair
                        _buildLogoutButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const PulseBottomNavigation(activeItem: PulseNavItem.profile),
      ),
    );
  }

  Widget _buildHeader(ProfileController controller) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(Get.context!).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF00324A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Center(
              child: _buildPulseFlowLogo(),
            ),
          ),
          _buildNotificationIcon(),
        ],
      ),
    );
  }

  Widget _buildPulseFlowLogo() {
    return Container(
      width: 140,
      height: 45,
      child: Image.asset(
        'assets/images/PulseNegativo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text(
                'PulseFlow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon() {
    if (!Get.isRegistered<HomeController>()) {
      return IconButton(
        icon: _notificationBadge(null),
        onPressed: () => Get.toNamed(Routes.NOTIFICATIONS),
      );
    }

    final homeController = Get.find<HomeController>();
    return Obx(() {
      final count = homeController.unreadNotificationsCount.value;
      return IconButton(
        icon: _notificationBadge(count),
        onPressed: () async {
          await Get.toNamed(Routes.NOTIFICATIONS);
          await homeController.loadNotificationsCount();
        },
      );
    });
  }

  Widget _notificationBadge(int? count) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        if (count != null && count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfilePhotoSection(ProfileController controller) {
    return Obx(() {
      final isEditing = controller.isEditing;
      final patient = controller.patient;
      final fullName = _displayValue(patient?.name);
      final createdAt = _formatDateDisplay(patient?.createdAt);
      final greeting = _resolveGreeting();
      final displayName = _combineNames(
        _extractFirstName(patient?.name),
        _extractLastName(patient?.name),
        fullName,
      );

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Sua Identidade',
                  style: AppTheme.titleMedium.copyWith(
                    color: const Color(0xFF00324A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: isEditing ? controller.cancelEditing : controller.enterEditingMode,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    foregroundColor: const Color(0xFF00324A),
                  ),
                  child: Text(isEditing ? 'Cancelar' : 'Editar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: isEditing ? () => _showPhotoOptions(controller) : null,
                  child: _buildAvatar(
                    controller: controller,
                    initials: _initialsFromName(fullName),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: AppTheme.bodyLarge.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: AppTheme.headlineSmall.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.withOpacity(0.25)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'membro desde : $createdAt',
                style: AppTheme.bodySmall.copyWith(
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPersonalDataSection(ProfileController controller) {
    return Obx(() {
      final isEditing = controller.isEditing;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF059669),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Dados Pessoais',
                  style: AppTheme.titleMedium.copyWith(
                    color: const Color(0xFF00324A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFieldTile(
              label: 'Nome Completo',
              controller: controller.nameController,
              isEditing: isEditing,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildFieldTile(
              label: 'Email',
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              isEditing: isEditing,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildFieldRow(
              children: [
                _buildFieldTile(
                  label: 'Telefone',
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  isEditing: isEditing,
                ),
                _buildFieldTile(
                  label: 'Data de Nascimento',
                  controller: controller.birthDateController,
                  isEditing: isEditing,
                  readOnly: true,
                  onTap: () => _selectDate(controller),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFieldRow(
              children: [
                _buildFieldTile(
                  label: 'CPF',
                  controller: controller.cpfController,
                  keyboardType: TextInputType.number,
                  isEditing: false,
                ),
                _buildFieldTile(
                  label: 'RG',
                  controller: controller.rgController,
                  isEditing: isEditing,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHealthDataSection(ProfileController controller) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Título da seção
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFFE91E63),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Dados de Saúde',
                style: AppTheme.titleMedium.copyWith(
                  color: const Color(0xFF00324A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Apple Health
          _buildHealthServiceCard(
            title: 'Apple Health',
            subtitle: 'Sincronize seus dados de saúde',
            icon: Icons.health_and_safety,
            color: const Color(0xFF059669),
            isConnected: controller.healthDataAccessGranted,
            onConnect: controller.requestHealthDataAccess,
            onDisconnect: controller.disconnectFromAppleHealth,
            isLoading: controller.isRequestingHealthPermissions,
          ),
          
          const SizedBox(height: 16),
          
          // Samsung Health
          _buildHealthServiceCard(
            title: 'Samsung Health',
            subtitle: 'Em breve - Sincronização com Samsung Health',
            icon: Icons.health_and_safety,
            color: const Color(0xFF1E40AF),
            isConnected: false,
            onConnect: controller.connectToSamsungHealth,
            onDisconnect: controller.disconnectFromSamsungHealth,
            isLoading: false,
          ),
          
          // Dados de saúde (se conectado)
          if (controller.healthDataAccessGranted) ...[
            const SizedBox(height: 20),
            _buildHealthDataDisplay(controller),
          ],
        ],
      ),
    ));
  }

  Widget _buildHealthServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isConnected,
    required VoidCallback onConnect,
    required VoidCallback onDisconnect,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
              ),
            )
          else
            GestureDetector(
              onTap: isConnected ? onDisconnect : onConnect,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.red : color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isConnected ? 'Desconectar' : 'Conectar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHealthDataDisplay(ProfileController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF059669).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sincronização de Dados',
            style: AppTheme.bodyLarge.copyWith(
              color: const Color(0xFF059669),
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Sincronize seus dados de saúde do Apple Health',
            style: AppTheme.bodySmall.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botão de ação
          Obx(() {
            final isLoading = controller.isRequestingHealthPermissions;
            return SizedBox(
              width: double.infinity,
                child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                    controller.syncHealthData();
                  },
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.sync, size: 20),
                label: Text(
                  isLoading
                      ? 'Sincronizando...'
                      : 'Sincronizar Dados',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                  style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF059669).withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            );
          }),
        ],
      ),
    );
  }


  Widget _buildFieldRow({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        final spacing = 16.0;
        final itemWidth = isWide ? (constraints.maxWidth - spacing) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: 16,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildFieldTile({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    TextInputType? keyboardType,
    bool readOnly = false,
    bool isRequired = false,
    VoidCallback? onTap,
  }) {
    final trimmedValue = controller.text.trim();
    final displayValue = trimmedValue.isEmpty ? 'Não informado' : trimmedValue;

    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              labelText: isRequired ? '$label *' : label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF00324A),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: AppTheme.bodyMedium.copyWith(
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Text(
            displayValue,
            style: AppTheme.bodyMedium.copyWith(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _displayValue(String? value) {
    if (value == null) return 'Não informado';
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Não informado' : trimmed;
  }

  String _extractFirstName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nome não informado';
    final parts = value.trim().split(' ');
    return parts.first;
  }

  String _extractLastName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Último nome não informado';
    final parts = value.trim().split(' ');
    return parts.length > 1 ? parts.last : 'Último nome não informado';
  }

  String _formatDateDisplay(DateTime? date) {
    if (date == null) return 'Não informado';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _combineNames(String firstName, String lastName, String fullName) {
    if (fullName != 'Não informado') {
      return fullName;
    }
    if (firstName.contains('não informado') && lastName.contains('não informado')) {
      return 'Nome não informado';
    }
    final buffer = StringBuffer();
    if (!firstName.contains('não informado')) {
      buffer.write(firstName);
    }
    if (!lastName.contains('não informado')) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(lastName);
    }
    return buffer.isEmpty ? 'Nome não informado' : buffer.toString();
  }

  Widget _buildAvatar({
    required ProfileController controller,
    required String initials,
  }) {
    final borderColor = const Color(0xFF00324A).withOpacity(0.3);

    Widget buildInitials() {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00324A).withOpacity(0.15),
              const Color(0xFF00324A).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: AppTheme.headlineSmall.copyWith(
              color: const Color(0xFF00324A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    Widget buildImage(ImageProvider provider) {
      return ClipOval(
        child: Image(
          image: provider,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return buildInitials();
          },
        ),
      );
    }

    Widget content;
    final photo = controller.profilePhoto;

    if (photo == null) {
      content = buildInitials();
    } else if (photo.startsWith('http')) {
      content = buildImage(NetworkImage(photo));
    } else if (photo.startsWith('data:image')) {
      try {
        final bytes = base64Decode(photo.split(',').last);
        content = ClipOval(
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return buildInitials();
            },
          ),
        );
      } catch (_) {
        content = buildInitials();
      }
    } else {
      final file = File(photo);
      content = buildImage(FileImage(file));
    }

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: content,
    );
  }

  String _initialsFromName(String name) {
    if (name.trim().isEmpty || name == 'Não informado') return 'PF';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }

  String _resolveGreeting() {
    try {
      final homeController = Get.find<HomeController>();
      final greeting = homeController.getGreeting();
      if (greeting.isNotEmpty) return greeting;
    } catch (_) {}
    return buildGreetingMessage();
  }

  Widget _buildSaveButton(ProfileController controller) {
    return Obx(() {
      if (!controller.isEditing) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00324A),
              const Color(0xFF00324A).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00324A).withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: controller.isSaving ? null : controller.savePatientData,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: controller.isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Salvando...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.save,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Salvar Alterações',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPrivacySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00324A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.history_outlined,
                color: Color(0xFF00324A),
                size: 24,
              ),
            ),
            title: const Text(
              'Histórico de Acessos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
            subtitle: const Text(
              'Veja quem acessou seu prontuário',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF757575),
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF757575),
            ),
            onTap: () {
              Get.toNamed(Routes.ACCESS_HISTORY);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
        onTap: () async {
          try {
            await AuthService.instance.logout();
          } catch (_) {}
          Get.offAllNamed(Routes.LOGIN);
        },
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text(
                'Sair',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoOptions(ProfileController controller) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Selecionar Foto',
              style: AppTheme.titleLarge.copyWith(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoOption(
                    icon: Icons.camera_alt,
                    label: 'Câmera',
                    onTap: () {
                      Navigator.pop(context);
                      controller.takePhotoWithCamera();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPhotoOption(
                    icon: Icons.photo_library,
                    label: 'Galeria',
                    onTap: () {
                      Navigator.pop(context);
                      controller.selectPhotoFromGallery();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF00324A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00324A).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF00324A),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTheme.titleSmall.copyWith(
                color: const Color(0xFF00324A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(ProfileController controller) async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      controller.birthDateController.text = 
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }
}