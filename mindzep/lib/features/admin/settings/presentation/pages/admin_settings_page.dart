import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        children: [
          _SectionHeader(label: 'App Settings'),
          AppCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  label: 'Push Notifications',
                  trailing: Switch(
                    value: true,
                    onChanged: (_) {},
                    activeColor: AppColors.primary,
                  ),
                ),
                const Divider(height: 1, indent: 48),
                // _SettingsTile(
                //   icon: Icons.verified_user_outlined,
                //   label: 'Auto-approve Psychologists',
                //   trailing: Switch(
                //     value: false,
                //     onChanged: (_) {},
                //     activeColor: AppColors.primary,
                //   ),
                // ),
                // const Divider(height: 1, indent: 48),
                // _SettingsTile(
                //   icon: Icons.currency_rupee_rounded,
                //   label: 'Platform Commission',
                //   subtitle: '20%',
                //   onTap: () => _showEditDialog(
                //       context, 'Commission (%)', '20'),
                // ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          _SectionHeader(label: 'Content Management'),
          AppCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.article_outlined,
                  label: 'Manage Blogs',
                  onTap: () => AppSnackbar.show(context,
                      message: 'Blog management coming soon',
                      type: SnackbarType.info),
                ),
                const Divider(height: 1, indent: 48),
                _SettingsTile(
                  icon: Icons.category_outlined,
                  label: 'Manage Specializations',
                  onTap: () => AppSnackbar.show(context,
                      message: 'Specialization management coming soon',
                      type: SnackbarType.info),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          _SectionHeader(label: 'Account'),
          AppCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admin Profile',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 48),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          AppButton(
            label: 'Logout',
            style: AppButtonStyle.danger,
            prefixIcon: Icons.logout_rounded,
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, String title, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppSnackbar.show(context,
                  message: 'Setting updated',
                  type: SnackbarType.success);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          bottom: AppDimensions.paddingS, left: 4),
      child: Text(label,
          style: AppTextStyles.footnote.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: AppTextStyles.body),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: AppTextStyles.caption1
                  .copyWith(color: AppColors.textSecondary))
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary)
              : null),
      onTap: onTap,
    );
  }
}
