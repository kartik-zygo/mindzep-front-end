import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/mock/mock_data.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_badge.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_snackbar.dart';

class AdminPsychManagementPage extends StatefulWidget {
  const AdminPsychManagementPage({super.key});

  @override
  State<AdminPsychManagementPage> createState() =>
      _AdminPsychManagementPageState();
}

class _AdminPsychManagementPageState
    extends State<AdminPsychManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Psychologist Management'),
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'All (${MockData.psychologists.length})'),
            Tab(
                text:
                    'Pending (${MockData.pendingPsychologists.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _AllPsychList(psychologists: MockData.psychologists),
          _PendingList(pending: MockData.pendingPsychologists),
        ],
      ),
    );
  }
}

class _AllPsychList extends StatelessWidget {
  final List<PsychologistEntity> psychologists;
  const _AllPsychList({required this.psychologists});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: psychologists.length,
      itemBuilder: (_, i) {
        final p = psychologists[i];
        return AppCard(
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
          child: Row(
            children: [
              AppAvatar(
                imageUrl: p.avatarUrl,
                radius: 22,
                availabilityStatus: p.status,
                showStatusDot: true,
                initials: p.name[0],
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: AppTextStyles.subheadline
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(p.specialization,
                        style: AppTextStyles.caption1.copyWith(
                            color: AppColors.textSecondary)),
                    Text(
                        '${p.ratingAverage.toStringAsFixed(1)} ★ · ${p.yearsExperience}y exp',
                        style: AppTextStyles.caption1.copyWith(
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => AppSnackbar.show(context,
                    message: '$v action applied',
                    type: SnackbarType.success),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'Suspend',
                      child: Text('Suspend')),
                  const PopupMenuItem(
                      value: 'Remove',
                      child: Text('Remove')),
                ],
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PendingList extends StatefulWidget {
  final List<PsychologistEntity> pending;
  const _PendingList({required this.pending});

  @override
  State<_PendingList> createState() => _PendingListState();
}

class _PendingListState extends State<_PendingList> {
  late List<PsychologistEntity> _pending;

  @override
  void initState() {
    super.initState();
    _pending = List.from(widget.pending);
  }

  @override
  Widget build(BuildContext context) {
    if (_pending.isEmpty) {
      return const Center(
          child: Text('No pending approvals'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: _pending.length,
      itemBuilder: (_, i) {
        final p = _pending[i];
        return AppCard(
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(
                    imageUrl: p.avatarUrl,
                    radius: 22,
                    initials: p.name[0],
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: AppTextStyles.subheadline.copyWith(
                                fontWeight: FontWeight.w600)),
                        Text(p.specialization,
                            style: AppTextStyles.caption1.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const StatusBadge(status: 'Pending'),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.error, size: 16),
                      label: const Text('Reject',
                          style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.error)),
                      onPressed: () {
                        setState(() => _pending.removeAt(i));
                        AppSnackbar.show(context,
                            message: '${p.name} rejected',
                            type: SnackbarType.error);
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingS),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16),
                      label: const Text('Approve',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                      onPressed: () {
                        setState(() => _pending.removeAt(i));
                        AppSnackbar.show(context,
                            message: '${p.name} approved!',
                            type: SnackbarType.success);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
