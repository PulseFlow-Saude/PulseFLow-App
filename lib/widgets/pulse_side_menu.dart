import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import 'pulse_bottom_navigation.dart';

class PulseSideMenu extends StatelessWidget {
  const PulseSideMenu({
    super.key,
    this.activeItem,
  });

  final PulseNavItem? activeItem;

  @override
  Widget build(BuildContext context) {
    final navigationItems = [
      _MenuItemData(
        navItem: PulseNavItem.home,
        icon: Icons.home,
        label: 'menu_home'.tr,
        route: Routes.HOME,
        useOffAll: true,
      ),
      _MenuItemData(
        navItem: PulseNavItem.history,
        icon: Icons.history,
        label: 'menu_history'.tr,
        route: Routes.HISTORY_SELECTION,
      ),
      _MenuItemData(
        navItem: PulseNavItem.menu,
        icon: Icons.library_books,
        label: 'menu_records'.tr,
        route: Routes.MENU,
      ),
      _MenuItemData(
        navItem: PulseNavItem.appointments,
        icon: Icons.calendar_today,
        label: 'menu_appointments'.tr,
        route: Routes.UPCOMING_APPOINTMENTS,
        useOffAll: true,
      ),
      _MenuItemData(
        navItem: PulseNavItem.pulseKey,
        icon: Icons.vpn_key,
        label: 'menu_pulse_key'.tr,
        route: Routes.PULSE_KEY,
      ),
      _MenuItemData(
        navItem: PulseNavItem.profile,
        icon: Icons.person,
        label: 'menu_profile'.tr,
        route: Routes.PROFILE,
      ),
    ];

    final institutionalItems = [
      _MenuItemData(
        icon: Icons.settings_outlined,
        label: 'menu_settings'.tr,
        route: Routes.SETTINGS,
      ),
      _MenuItemData(
        icon: Icons.info_outline,
        label: 'inst_about_title'.tr,
        route: Routes.ABOUT,
      ),
      _MenuItemData(
        icon: Icons.help_outline,
        label: 'inst_faq_title'.tr,
        route: Routes.FAQ,
      ),
      _MenuItemData(
        icon: Icons.shield_outlined,
        label: 'inst_security_title'.tr,
        route: Routes.SECURITY,
      ),
      _MenuItemData(
        icon: Icons.privacy_tip_outlined,
        label: 'inst_privacy_title'.tr,
        route: Routes.PRIVACY,
      ),
      _MenuItemData(
        icon: Icons.support_agent_outlined,
        label: 'inst_contact_title'.tr,
        route: Routes.CONTACT,
      ),
      _MenuItemData(
        icon: Icons.system_update_alt_outlined,
        label: 'inst_version_title'.tr,
        route: Routes.APP_VERSION,
      ),
    ];

    final width = MediaQuery.of(context).size.width;
    final drawerWidth = width < 360 ? width : 320.0;
    final isCompact = drawerWidth <= 300;
    final mediaPadding = MediaQuery.of(context).padding;

    return Drawer(
      width: drawerWidth,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF002538),
              Color(0xFF00324A),
            ],
          ),
        ),
        child: SafeArea(
          left: false,
          right: false,
          child: Column(
            children: [
              _DrawerHeader(
                isCompact: isCompact,
                topPadding: mediaPadding.top,
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 1,
                color: Colors.white.withOpacity(0.15),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  children: [
                    for (final data in navigationItems) ...[
                      _PulseSideMenuTile(
                        data: data,
                        isActive: data.navItem != null && data.navItem == activeItem,
                        onTap: () => _handleTap(context, data),
                        isCompact: isCompact,
                      ),
                      const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'menu_institutional'.tr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final data in institutionalItems) ...[
                      _PulseSideMenuTile(
                        data: data,
                        isActive: false,
                        onTap: () => _handleTap(context, data),
                        isCompact: isCompact,
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, _MenuItemData data) {
    Navigator.of(context).pop();
    if (data.navItem != null && activeItem == data.navItem) return;
    if (data.route == null) return;
    if (data.useOffAll) {
      Get.offAllNamed(data.route!);
    } else {
      Get.toNamed(data.route!);
    }
  }
}

class _MenuItemData {
  _MenuItemData({
    required this.icon,
    required this.label,
    this.route,
    this.navItem,
    this.useOffAll = false,
  });

  final PulseNavItem? navItem;
  final IconData icon;
  final String label;
  final String? route;
  final bool useOffAll;
}

class _PulseSideMenuTile extends StatelessWidget {
  const _PulseSideMenuTile({
    required this.data,
    required this.isActive,
    required this.onTap,
    required this.isCompact,
  });

  final _MenuItemData data;
  final bool isActive;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;
    final iconColor = Colors.white;
    final indicatorColor = isActive ? Colors.white : Colors.white.withOpacity(0.3);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 14,
          vertical: 8,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 18),
            Icon(
              data.icon,
              color: iconColor,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                data.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.isCompact,
    required this.topPadding,
  });

  final bool isCompact;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isCompact ? 18 : 22,
      ).copyWith(
        top: (isCompact ? 18 : 22) + topPadding,
      ),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Image.asset(
              'assets/images/PulseNegativo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Centralize seus cuidados em um só lugar',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

