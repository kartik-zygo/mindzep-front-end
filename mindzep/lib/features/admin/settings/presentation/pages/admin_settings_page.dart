import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';

/// Admin settings.
///
/// Every control on this screen performs a real action. Placeholder toggles,
/// "coming soon" tiles and dialogs that reported success without saving have
/// been removed — an admin reviewing this screen should never be shown a
/// control that does nothing.
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
          _SectionHeader(label: 'Content Management'),
          AppCard(
            child: _SettingsTile(
              icon: Icons.article_outlined,
              label: 'Manage Blogs',
              onTap: () => context.go(RouteNames.adminBlogs),
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
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: AppTextStyles.body),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
