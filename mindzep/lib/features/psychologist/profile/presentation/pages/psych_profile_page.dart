import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../auth/data/models/auth_models.dart';
import '../../../../auth/data/repositories/auth_repository.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../data/models/psychologist_models.dart';
import '../../../data/repositories/psychologist_repository.dart';

class PsychProfilePage extends StatefulWidget {
  const PsychProfilePage({super.key});

  @override
  State<PsychProfilePage> createState() => _PsychProfilePageState();
}

class _PsychProfilePageState extends State<PsychProfilePage> {
  late final PsychologistRepository _psychologistRepository;
  late final AuthRepository _authRepository;

  bool _loading = true;
  PsychologistEntity? _psychologist;
  List<PsychologistDocumentModel> _documents = const <PsychologistDocumentModel>[];

  @override
  void initState() {
    super.initState();
    _psychologistRepository = sl<PsychologistRepository>();
    _authRepository = sl<AuthRepository>();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
    });

    // Load profile and documents independently so partial data still shows
    try {
      final profile = await _psychologistRepository.getMyProfile();
      if (!mounted) return;
      setState(() {
        _psychologist = profile.toEntity();
      });
    } catch (e) {
      debugPrint('[MindZep] PsychProfile profile error: $e');
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: e.toString(),
        type: SnackbarType.error,
      );
    }

    try {
      final documents = await _psychologistRepository.listMyDocuments();
      if (!mounted) return;
      setState(() {
        _documents = documents..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (e) {
      debugPrint('[MindZep] PsychProfile documents error: $e');
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final psych = _psychologist ??
        PsychologistEntity(
          id: 'me',
          name: 'Psychologist',
          credentials: '-',
          specialization: 'General',
          specializations: const <String>['General'],
          languages: const <String>['English'],
          yearsExperience: 0,
          ratingAverage: 0,
          totalReviews: 0,
          totalSessions: 0,
          ratePerMinute: 0,
          freeMinutes: 2,
          status: AvailabilityStatus.offline,
          avatarUrl: null,
          bio: null,
          isApproved: true,
          isActive: true,
          createdAt: DateTime.now(),
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Teal Gradient Header ──────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2196A6), Color(0xFF30B0C7), Color(0xFF34C7A3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    children: [
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                      // Top row: title + edit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Profile',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: _loading ? null : () => _showEditProfileSheet(context, psych),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Edit', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Avatar
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: ClipOval(
                          child: AppAvatar(
                            imageUrl: psych.avatarUrl,
                            radius: 40,
                            initials: _initials(psych.name),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(psych.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        psych.specialization,
                        style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _HeaderStat(value: psych.ratingAverage.toStringAsFixed(1), label: 'Rating'),
                          _StatDivider(),
                          _HeaderStat(value: '${psych.yearsExperience}y', label: 'Experience'),
                          _StatDivider(),
                          _HeaderStat(value: '${psych.totalReviews}', label: 'Reviews'),
                          _StatDivider(),
                          _HeaderStat(value: '₹${psych.ratePerMinute}/m', label: 'Rate'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
          // Bio
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About',
                            style: AppTextStyles.headline
                                .copyWith(color: AppColors.textPrimary)),
                        const SizedBox(height: AppDimensions.paddingS),
                        Text(
                          psych.bio ??
                              'Experienced psychologist specializing in ${psych.specialization}.',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  // Specializations
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Specializations',
                            style: AppTextStyles.headline
                                .copyWith(color: AppColors.textPrimary)),
                        const SizedBox(height: AppDimensions.paddingS),
                        Wrap(
                          spacing: AppDimensions.paddingS,
                          runSpacing: AppDimensions.paddingS,
                          children: psych.specializations
                              .map((s) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F8FB),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      s,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF30B0C7)),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Documents',
                              style: AppTextStyles.headline
                                  .copyWith(color: AppColors.textPrimary),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F8FB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_documents.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF30B0C7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingS),
                        if (_documents.isEmpty)
                          Text(
                            'No uploaded documents found.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          ..._documents.take(3).map(
                                (doc) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppDimensions.paddingXS),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.description_outlined,
                                        size: 16,
                                        color: Color(0xFF30B0C7),
                                      ),
                                      const SizedBox(width: AppDimensions.paddingS),
                                      Expanded(
                                        child: Text(
                                          doc.documentType ?? 'Document',
                                          style: AppTextStyles.subheadline.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}',
                                        style: AppTextStyles.caption1.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        if (_documents.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: AppDimensions.paddingXS),
                            child: Text(
                              '+${_documents.length - 3} more documents',
                              style: AppTextStyles.caption1.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  // Actions menu
                  AppCard(
                    child: Column(
                      children: [
                        _MenuItem(
                          icon: Icons.edit_outlined,
                          label: 'Edit Profile',
                          iconColor: const Color(0xFF30B0C7),
                          onTap: _loading ? () {} : () => _showEditProfileSheet(context, psych),
                        ),
                        const Divider(height: 1, indent: 48),
                        _MenuItem(
                          icon: Icons.lock_outline_rounded,
                          label: 'Change Password',
                          iconColor: const Color(0xFF30B0C7),
                          onTap: _showChangePasswordDialog,
                        ),
                        const Divider(height: 1, indent: 48),
                        _MenuItem(
                          icon: Icons.help_outline_rounded,
                          label: 'Help & Support',
                          iconColor: const Color(0xFF30B0C7),
                          onTap: () => _showHelpModal(context),
                        ),
                        const Divider(height: 1, indent: 48),
                        _MenuItem(
                          icon: Icons.star_outline_rounded,
                          label: 'Rate MindZep',
                          iconColor: const Color(0xFFFF9500),
                          onTap: () => _showRatingDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(const LogoutRequested());
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _showEditProfileSheet(BuildContext context, PsychologistEntity psych) {
    final bioCtrl = TextEditingController(text: psych.bio ?? '');
    final rateCtrl = TextEditingController(text: psych.ratePerMinute.toStringAsFixed(0));
    final languagesCtrl = TextEditingController(text: psych.languages.join(', '));
    final specializationsCtrl = TextEditingController(text: psych.specializations.join(', '));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
              const SizedBox(height: 20),
              Text(
                psych.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E)),
              ),
              const SizedBox(height: 14),
              const Text('Bio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(14)),
                child: TextField(
                  controller: bioCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                  decoration: const InputDecoration(hintText: 'Tell patients about yourself...', hintStyle: TextStyle(color: Color(0xFFC7C7CC)), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Rate Per Minute', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(14)),
                child: TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                  decoration: const InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Languages (comma separated)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(14)),
                child: TextField(
                  controller: languagesCtrl,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                  decoration: const InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Specializations (comma separated)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(14)),
                child: TextField(
                  controller: specializationsCtrl,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                  decoration: const InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    final rateValue = double.tryParse(rateCtrl.text.trim());
                    if (rateValue == null || rateValue <= 0) {
                      AppSnackbar.show(
                        context,
                        message: 'Enter a valid rate per minute.',
                        type: SnackbarType.error,
                      );
                      return;
                    }

                    final languages = languagesCtrl.text
                        .split(',')
                        .map((item) => item.trim())
                        .where((item) => item.isNotEmpty)
                        .toList();
                    final specializations = specializationsCtrl.text
                        .split(',')
                        .map((item) => item.trim())
                        .where((item) => item.isNotEmpty)
                        .toList();

                    try {
                      final updated = await _psychologistRepository.updateMyProfile(
                        PsychologistUpdateRequest(
                          bio: bioCtrl.text.trim(),
                          ratePerMinute: rateValue,
                          languages: languages,
                          specializations: specializations,
                        ),
                      );

                      if (!mounted) return;
                      setState(() {
                        _psychologist = updated.toEntity();
                      });
                      Navigator.pop(context);
                      AppSnackbar.show(
                        context,
                        message: 'Profile updated successfully!',
                        type: SnackbarType.success,
                      );
                    } catch (_) {
                      if (!mounted) return;
                      AppSnackbar.show(
                        context,
                        message: 'Unable to update profile right now.',
                        type: SnackbarType.error,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PasswordField(controller: currentCtrl, hint: 'Current password'),
            const SizedBox(height: 12),
            _PasswordField(controller: newCtrl, hint: 'New password'),
            const SizedBox(height: 12),
            _PasswordField(controller: confirmCtrl, hint: 'Confirm new password'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E8E93)))),
          GestureDetector(
            onTap: () async {
              final current = currentCtrl.text;
              final next = newCtrl.text;
              final confirm = confirmCtrl.text;

              if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
                AppSnackbar.show(
                  context,
                  message: 'Please fill all password fields.',
                  type: SnackbarType.error,
                );
                return;
              }

              if (next != confirm) {
                AppSnackbar.show(
                  context,
                  message: 'New password and confirm password must match.',
                  type: SnackbarType.error,
                );
                return;
              }

              try {
                await _authRepository.changePassword(
                  ChangePasswordRequest(
                    currentPassword: current,
                    newPassword: next,
                    confirmPassword: confirm,
                  ),
                );

                if (!mounted) return;
                Navigator.pop(context);
                AppSnackbar.show(
                  context,
                  message: 'Password changed successfully!',
                  type: SnackbarType.success,
                );
              } catch (_) {
                if (!mounted) return;
                AppSnackbar.show(
                  context,
                  message: 'Unable to change password right now.',
                  type: SnackbarType.error,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)]), borderRadius: BorderRadius.circular(12)),
              child: const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _showHelpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Icon(Icons.support_agent_rounded, size: 48, color: Color(0xFF30B0C7)),
            const SizedBox(height: 12),
            const Text('Help & Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Need help? Our support team is available 24/7 to assist you.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
            const SizedBox(height: 20),
            _HelpOption(icon: Icons.email_outlined, label: 'Email Support', value: 'support@mindzep.com'),
            const SizedBox(height: 8),
            _HelpOption(icon: Icons.phone_outlined, label: 'Phone Support', value: '+91 98765 43210'),
            const SizedBox(height: 8),
            _HelpOption(icon: Icons.chat_bubble_outline_rounded, label: 'Live Chat', value: 'Available in-app'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    int _rating = 0;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Text('⭐', style: TextStyle(fontSize: 36)),
              SizedBox(height: 8),
              Text('Rate MindZep', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('How\'s your experience?', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93), fontWeight: FontWeight.normal)),
            ],
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setDialogState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFFFF9500), size: 36),
              ),
            )),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip', style: TextStyle(color: Color(0xFF8E8E93)))),
            GestureDetector(
              onTap: _rating == 0 ? null : () {
                Navigator.pop(context);
                AppSnackbar.show(context, message: 'Thank you for your feedback!', type: SnackbarType.success);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  gradient: _rating > 0 ? const LinearGradient(colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)]) : null,
                  color: _rating == 0 ? const Color(0xFFE5E5EA) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Submit', style: TextStyle(color: _rating > 0 ? Colors.white : const Color(0xFF8E8E93), fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String value, label;
  const _HeaderStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Colors.white.withOpacity(0.3));
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(label, style: AppTextStyles.body),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  const _PasswordField({required this.controller, required this.hint});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscure,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: Color(0xFFC7C7CC)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFF8E8E93)),
          ),
        ),
      ),
    );
  }
}

class _HelpOption extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _HelpOption({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFF30B0C7).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF30B0C7), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

