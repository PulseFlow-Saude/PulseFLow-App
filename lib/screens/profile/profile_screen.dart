import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import 'profile_controller.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_drawer_button.dart';
import '../../widgets/pulse_blue_screen_shell.dart';
import '../../services/auth_service.dart';
import '../home/home_controller.dart';
import '../../utils/greeting_utils.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return PulseBlueScaffold(
      drawer: PulseSideMenu(activeItem: PulseNavItem.profile),
      header: _buildHeader(controller),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          );
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfilePhotoSection(controller),
              const SizedBox(height: 20),
              _buildPersonalDataSection(controller),
              const SizedBox(height: 20),
              _buildHealthDataSection(controller),
              const SizedBox(height: 20),
              _buildPrivacySection(),
              const SizedBox(height: 20),
              _buildSaveButton(controller),
              const SizedBox(height: 20),
              _buildLogoutButton(),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(ProfileController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
      child: Row(
        children: [
          const PulseDrawerButton(iconSize: 22),
          Expanded(
            child: Center(
              child: _buildBrandLogo(),
            ),
          ),
          _buildNotificationIcon(),
        ],
      ),
    );
  }

  Widget _buildBrandLogo() {
    return Container(
      width: 140,
      height: 45,
      child: Image.asset(
        'assets/images/oryon_health_logo_negative.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Text(
                'Oryon Health',
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
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
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
                  'profile_identity'.tr,
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
                  child: Text(isEditing ? 'profile_cancel'.tr : 'profile_edit'.tr),
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
                        greeting.tr,
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
                '${'profile_member_since'.tr} : $createdAt',
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
                  'profile_personal_data'.tr,
                  style: AppTheme.titleMedium.copyWith(
                    color: const Color(0xFF00324A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFieldTile(
              label: 'profile_full_name'.tr,
              controller: controller.nameController,
              isEditing: isEditing,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildFieldTile(
              label: 'profile_email'.tr,
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              isEditing: isEditing,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildFieldRow(
              children: [
                _buildFieldTile(
                  label: 'profile_phone'.tr,
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  isEditing: isEditing,
                ),
                _buildFieldTile(
                  label: 'profile_birth_date'.tr,
                  controller: controller.birthDateController,
                  isEditing: isEditing,
                  readOnly: true,
                  onTap: () => _selectDate(controller),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Builder(builder: (_) {
              final p = controller.patient;
              final showSsn =
                  controller.patientShowsUsSocialSecurity(p);
              return _buildFieldRow(
                children: [
                  _buildFieldTile(
                    label:
                        showSsn ? 'profile_ssn_us'.tr : 'profile_cpf'.tr,
                    controller: controller.cpfController,
                    keyboardType: TextInputType.number,
                    isEditing: false,
                  ),
                  if (!showSsn)
                    _buildFieldTile(
                      label: 'profile_rg'.tr,
                      controller: controller.rgController,
                      isEditing: isEditing,
                    ),
                ],
              );
            }),
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
                'profile_health_data'.tr,
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
            title: 'profile_apple_health'.tr,
            subtitle: 'profile_apple_health_sub'.tr,
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
            title: 'profile_samsung_health'.tr,
            subtitle: 'profile_samsung_health_sub'.tr,
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
                  isConnected ? 'profile_disconnect'.tr : 'profile_connect'.tr,
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
            'profile_sync_title'.tr,
            style: AppTheme.bodyLarge.copyWith(
              color: const Color(0xFF059669),
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'profile_sync_sub'.tr,
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
                      ? 'profile_syncing'.tr
                      : 'profile_sync_data'.tr,
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
        const spacing = 16.0;
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
    final displayValue = trimmedValue.isEmpty ? 'profile_not_informed'.tr : trimmedValue;

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
    if (value == null) return 'profile_not_informed'.tr;
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'profile_not_informed'.tr : trimmed;
  }

  String _extractFirstName(String? value) {
    if (value == null || value.trim().isEmpty) return 'profile_name_not_informed'.tr;
    final parts = value.trim().split(' ');
    return parts.first;
  }

  String _extractLastName(String? value) {
    if (value == null || value.trim().isEmpty) return 'profile_lastname_not_informed'.tr;
    final parts = value.trim().split(' ');
    return parts.length > 1 ? parts.last : 'profile_lastname_not_informed'.tr;
  }

  String _formatDateDisplay(DateTime? date) {
    if (date == null) return 'profile_not_informed'.tr;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _combineNames(String firstName, String lastName, String fullName) {
    final notInformed = 'profile_not_informed'.tr;
    final nameNotInformed = 'profile_name_not_informed'.tr;
    final lastnameNotInformed = 'profile_lastname_not_informed'.tr;
    if (fullName != notInformed) return fullName;
    if (firstName == nameNotInformed && lastName == lastnameNotInformed) return nameNotInformed;
    final buffer = StringBuffer();
    if (firstName != nameNotInformed) buffer.write(firstName);
    if (lastName != lastnameNotInformed) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(lastName);
    }
    return buffer.isEmpty ? nameNotInformed : buffer.toString();
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
    } else if (photo.startsWith('data:image') || _isBase64Photo(photo)) {
      try {
        final bytes = photo.startsWith('data:image')
            ? base64Decode(photo.split(',').last)
            : base64Decode(photo);
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

  bool _isBase64Photo(String photo) {
    return photo.startsWith('data:image/') ||
        (!photo.startsWith('http') && !photo.startsWith('/') && photo.length > 100);
  }

  String _initialsFromName(String name) {
    if (name.trim().isEmpty || name == 'profile_not_informed'.tr) return 'PF';
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
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'profile_saving'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.save,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'profile_save_changes'.tr,
                          style: const TextStyle(
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
            title: Text(
              'profile_access_history'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
            subtitle: Text(
              'profile_access_history_sub'.tr,
              style: const TextStyle(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Text(
                'profile_logout'.tr,
                style: const TextStyle(
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
              'profile_select_photo'.tr,
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
                    label: 'profile_camera'.tr,
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
                    label: 'profile_gallery'.tr,
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