import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/settings_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../splash/splash_screen.dart';
import '../navigation/main_navigation_shell.dart';

/// Profile and Settings Screen matching the traveltales_profile_settings_screen UI reference.
///
/// Implements:
/// - User profile header (avatar, name, email)
/// - "My Trips" navigation option
/// - "Notifications" settings and toggle
/// - "Help & Support" information sheet
/// - "Settings" preferences sheet (Offline storage toggle, currency, app version)
/// - "Logout" flow with confirmation dialog returning cleanly to Splash
class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  void _onMyTripsTapped(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationShell(initialIndex: 0)),
      );
    }
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Consumer<SettingsProvider>(
          builder: (ctx, settings, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.subtle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Notification Preferences',
                            style: AppTypography.brandTitle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('close_notifications_sheet'),
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
                          onPressed: () => Navigator.of(bottomSheetContext).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primaryTeal,
                      title: const Text(
                        'Push Notifications',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                      subtitle: const Text(
                        'Receive real-time alerts for trips and updates',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      value: settings.notificationsEnabled,
                      onChanged: (val) {
                        settings.setNotificationsEnabled(val);
                      },
                    ),
                    const Divider(height: 16, color: AppColors.subtle),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primaryTeal,
                      title: const Text(
                        'Trip & Activity Reminders',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                      subtitle: const Text(
                        'Alerts before upcoming itinerary activities',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      value: settings.tripRemindersEnabled,
                      onChanged: (val) {
                        settings.setTripRemindersEnabled(val);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHelpSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.subtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Help & Support',
                        style: AppTypography.brandTitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('close_help_support_sheet'),
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
                      onPressed: () => Navigator.of(ctx).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHelpItem(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email Support',
                  subtitle: 'support@traveltales.app',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Support email copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  icon: Icons.question_answer_outlined,
                  title: 'FAQs & Itinerary Guide',
                  subtitle: 'Learn how to plan trips, track expenses, and view maps',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('TravelTales Knowledge Base loaded'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  icon: Icons.info_outline_rounded,
                  title: 'App Version',
                  subtitle: 'TravelTales v1.0.0 (Build 2025.1)',
                  onTap: null,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  static Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryTeal, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Consumer<SettingsProvider>(
          builder: (ctx, settings, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.subtle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'App Settings',
                            style: AppTypography.brandTitle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('close_settings_sheet'),
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
                          onPressed: () => Navigator.of(bottomSheetContext).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primaryTeal,
                      title: const Text(
                        'Offline Data Storage',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                      subtitle: const Text(
                        'Save trips, activities & expenses locally in Hive',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      value: settings.offlineStorageEnabled,
                      onChanged: (val) {
                        settings.setOfflineStorageEnabled(val);
                      },
                    ),
                    const Divider(height: 16, color: AppColors.subtle),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Currency',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                      subtitle: Text(
                        settings.currency,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                      onTap: () {
                        // Toggle between INR and USD for demo
                        final newCurr = settings.currency.contains('INR') ? 'USD (\$)' : 'INR (₹)';
                        settings.setCurrency(newCurr);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text(
            'Log Out',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of TravelTales?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Clear user-scoped in-memory state and terminate session
                try {
                  context.read<TripProvider>().clear();
                } catch (_) {}
                try {
                  context.read<ExpenseProvider>().clear();
                } catch (_) {}
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final tripCount = context.watch<TripProvider>().trips.length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          key: const ValueKey('profile_back_button'),
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: AppColors.charcoal,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainNavigationShell(initialIndex: 0)),
              );
            }
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              // User Profile Card (Avatar, Name, Email)
              _buildUserProfileHeader(settings),
              const SizedBox(height: 24),
              // Menu Options Container
              _buildMenuOptions(context, tripCount),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileHeader(SettingsProvider settings) {
    return Column(
      children: [
        // User Avatar with Border Accent & Subtle Ring
        Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.06),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
            border: Border.all(
              color: AppColors.subtle,
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: Image.network(
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.primaryLight,
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryTeal,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // User Name
        Text(
          settings.userName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // User Email
        Text(
          settings.userEmail,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.muted,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuOptions(BuildContext context, int tripCount) {
    return Column(
      children: [
        // Menu Item: My Trips
        _buildMenuItem(
          icon: Icons.luggage_outlined,
          title: 'My Trips',
          badgeText: '$tripCount Trips',
          onTap: () => _onMyTripsTapped(context),
        ),
        const SizedBox(height: 10),

        // Menu Item: Notifications
        _buildMenuItem(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          onTap: () => _showNotificationsSheet(context),
        ),
        const SizedBox(height: 10),

        // Menu Item: Help & Support
        _buildMenuItem(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          onTap: () => _showHelpSupportSheet(context),
        ),
        const SizedBox(height: 10),

        // Menu Item: Settings
        _buildMenuItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () => _showSettingsSheet(context),
        ),
        const SizedBox(height: 10),

        // Menu Item: Logout
        _buildMenuItem(
          icon: Icons.logout_rounded,
          title: 'Logout',
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.03),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(width: 14),
              // Menu label
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              if (badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Trailing chevron
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
