import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/mock/mock_data.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_snackbar.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState
    extends State<AdminUserManagementPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = MockData.adminUsers
        .where((u) =>
            _searchQuery.isEmpty ||
            u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM),
              itemCount: users.length,
              itemBuilder: (_, i) {
                final u = users[i];
                return AppCard(
                  margin: const EdgeInsets.only(
                      bottom: AppDimensions.paddingS),
                  child: Row(
                    children: [
                      AppAvatar(
                        imageUrl: u.avatarUrl,
                        radius: 22,
                        initials: u.name[0],
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.name,
                                style: AppTextStyles.subheadline
                                    .copyWith(
                                        fontWeight: FontWeight.w600)),
                            Text(u.email,
                                style: AppTextStyles.caption1.copyWith(
                                    color: AppColors.textSecondary)),
                            if (u.phone != null)
                              Text(u.phone!,
                                  style: AppTextStyles.caption2.copyWith(
                                      color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: u.isActive
                                  ? AppColors.success.withOpacity(0.12)
                                  : AppColors.error.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusFull),
                            ),
                            child: Text(
                              u.isActive ? 'Active' : 'Suspended',
                              style: AppTextStyles.caption2.copyWith(
                                color: u.isActive
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => AppSnackbar.show(context,
                                message: u.isActive
                                    ? '${u.name} suspended'
                                    : '${u.name} reactivated',
                                type: u.isActive
                                    ? SnackbarType.warning
                                    : SnackbarType.success),
                            child: Text(
                              u.isActive ? 'Suspend' : 'Reactivate',
                              style: AppTextStyles.caption1.copyWith(
                                  color: u.isActive
                                      ? AppColors.error
                                      : AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
