import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../auth/data/models/auth_models.dart';
import '../../../../auth/data/repositories/auth_repository.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../data/models/psychologist_models.dart';
import '../../../data/repositories/psychologist_repository.dart';
import '../../../shared/psych_ui.dart';

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
  List<PsychologistDocumentModel> _documents =
      const <PsychologistDocumentModel>[];

  @override
  void initState() {
    super.initState();
    _psychologistRepository = sl<PsychologistRepository>();
    _authRepository = sl<AuthRepository>();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    try {
      final profile = await _psychologistRepository.getMyProfile();
      if (!mounted) return;
      setState(() => _psychologist = profile.toEntity());
    } catch (e) {
      debugPrint('[MindZep] PsychProfile profile error: $e');
      if (!mounted) return;
      AppSnackbar.show(context, message: e.toString(), type: SnackbarType.error);
    }

    try {
      final documents = await _psychologistRepository.listMyDocuments();
      if (!mounted) return;
      setState(() => _documents = documents
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    } catch (e) {
      debugPrint('[MindZep] PsychProfile documents error: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final psych = _psychologist ?? _fallbackPsych();

    return PsychScaffold(
      body: RefreshIndicator(
        color: PsychPalette.teal,
        onRefresh: _loadProfile,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(psych)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PsychFadeIn(child: _buildAbout(psych)),
                    const SizedBox(height: 12),
                    PsychFadeIn(
                        delayMs: 60, child: _buildSpecializations(psych)),
                    const SizedBox(height: 12),
                    PsychFadeIn(delayMs: 100, child: _buildDocuments()),
                    const SizedBox(height: 12),
                    PsychFadeIn(delayMs: 140, child: _buildActions(psych)),
                    const SizedBox(height: 16),
                    PsychFadeIn(delayMs: 180, child: _buildSignOut()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PsychologistEntity psych) {
    return PsychGradientHeader(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      child: Column(
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              GestureDetector(
                onTap:
                    _loading ? null : () => _showEditProfileSheet(context, psych),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(PsychRadii.pill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 5),
                      Text('Edit',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child: AppAvatar(
                imageUrl: psych.avatarUrl,
                radius: 44,
                initials: _initials(psych.name),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            psych.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(PsychRadii.pill),
            ),
            child: Text(
              psych.specialization,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              PsychGlassStat(
                  value: psych.ratingAverage.toStringAsFixed(1),
                  label: 'Rating'),
              const SizedBox(width: 10),
              PsychGlassStat(
                  value: '${psych.yearsExperience}y', label: 'Experience'),
              const SizedBox(width: 10),
              PsychGlassStat(
                  value: '${psych.totalReviews}', label: 'Reviews'),
              const SizedBox(width: 10),
              PsychGlassStat(
                  value: '${psych.totalSessions}', label: 'Sessions'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbout(PsychologistEntity psych) {
    return PsychCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.person_outline_rounded, title: 'About'),
          const SizedBox(height: 10),
          Text(
            psych.bio ??
                'Experienced psychologist specializing in ${psych.specialization}.',
            style: const TextStyle(
                color: PsychPalette.inkSoft, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializations(PsychologistEntity psych) {
    final specs = psych.specializations.isEmpty
        ? [psych.specialization]
        : psych.specializations;
    return PsychCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
              icon: Icons.workspace_premium_outlined,
              title: 'Specializations'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specs
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: PsychPalette.tealMist,
                        borderRadius: BorderRadius.circular(PsychRadii.pill),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: PsychPalette.tealDeep),
                      ),
                    ))
                .toList(),
          ),
          if (psych.languages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.translate_rounded,
                    size: 16, color: PsychPalette.inkFaint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    psych.languages.join(' · '),
                    style: const TextStyle(
                        fontSize: 13, color: PsychPalette.inkSoft),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocuments() {
    return PsychCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CardTitle(
                  icon: Icons.folder_open_rounded, title: 'Documents'),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: PsychPalette.tealMist,
                  borderRadius: BorderRadius.circular(PsychRadii.pill),
                ),
                child: Text(
                  '${_documents.length}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: PsychPalette.tealDeep),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_documents.isEmpty)
            const Text(
              'No uploaded documents found.',
              style: TextStyle(color: PsychPalette.inkSoft, fontSize: 13),
            )
          else
            ..._documents.take(4).map(
                  (doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: PsychPalette.tealMist,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.description_rounded,
                              size: 17, color: PsychPalette.tealDeep),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            doc.documentType ?? 'Document',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: PsychPalette.ink),
                          ),
                        ),
                        Text(
                          '${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}',
                          style: const TextStyle(
                              fontSize: 12, color: PsychPalette.inkFaint),
                        ),
                      ],
                    ),
                  ),
                ),
          if (_documents.length > 4)
            Text(
              '+${_documents.length - 4} more documents',
              style: const TextStyle(fontSize: 12, color: PsychPalette.inkSoft),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(PsychologistEntity psych) {
    return PsychCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            iconColor: PsychPalette.teal,
            onTap: _loading ? () {} : () => _showEditProfileSheet(context, psych),
          ),
          const _MenuDivider(),
          _MenuItem(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            iconColor: PsychPalette.teal,
            onTap: _showChangePasswordDialog,
          ),
          const _MenuDivider(),
          _MenuItem(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            iconColor: PsychPalette.teal,
            onTap: () => _showHelpModal(context),
          ),
          const _MenuDivider(),
          _MenuItem(
            icon: Icons.star_outline_rounded,
            label: 'Rate MindZep',
            iconColor: PsychPalette.warning,
            onTap: () => _showRatingDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOut() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Sign Out',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: PsychPalette.danger.withValues(alpha: 0.1),
          foregroundColor: PsychPalette.danger,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PsychRadii.pill)),
        ),
      ),
    );
  }

  PsychologistEntity _fallbackPsych() => PsychologistEntity(
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

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  // ── Edit profile sheet ────────────────────────────────────────────────────

  void _showEditProfileSheet(BuildContext context, PsychologistEntity psych) {
    final bioCtrl = TextEditingController(text: psych.bio ?? '');
    final languagesCtrl =
        TextEditingController(text: psych.languages.join(', '));
    final specializationsCtrl =
        TextEditingController(text: psych.specializations.join(', '));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
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
                        color: const Color(0xFFE5EAED),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Edit Profile',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: PsychPalette.ink)),
                const SizedBox(height: 18),
                _SheetField(label: 'Bio', controller: bioCtrl, maxLines: 3, hint: 'Tell patients about yourself...'),
                const SizedBox(height: 14),
                _SheetField(
                    label: 'Languages (comma separated)',
                    controller: languagesCtrl,
                    hint: 'English, Hindi'),
                const SizedBox(height: 14),
                _SheetField(
                    label: 'Specializations (comma separated)',
                    controller: specializationsCtrl,
                    hint: 'Anxiety, Depression'),
                const SizedBox(height: 22),
                PsychPrimaryButton(
                  label: 'Save Changes',
                  icon: Icons.check_rounded,
                  onPressed: () async {
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
                      final updated =
                          await _psychologistRepository.updateMyProfile(
                        PsychologistUpdateRequest(
                          bio: bioCtrl.text.trim(),
                          languages: languages,
                          specializations: specializations,
                        ),
                      );

                      if (!mounted) return;
                      setState(() => _psychologist = updated.toEntity());
                      Navigator.pop(context);
                      AppSnackbar.show(context,
                          message: 'Profile updated successfully!',
                          type: SnackbarType.success);
                    } catch (_) {
                      if (!mounted) return;
                      AppSnackbar.show(context,
                          message: 'Unable to update profile right now.',
                          type: SnackbarType.error);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Change password ───────────────────────────────────────────────────────

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: PsychPalette.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PasswordField(controller: currentCtrl, hint: 'Current password'),
            const SizedBox(height: 12),
            _PasswordField(controller: newCtrl, hint: 'New password'),
            const SizedBox(height: 12),
            _PasswordField(
                controller: confirmCtrl, hint: 'Confirm new password'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: PsychPalette.inkSoft)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PsychPalette.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final current = currentCtrl.text;
              final next = newCtrl.text;
              final confirm = confirmCtrl.text;

              if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
                AppSnackbar.show(context,
                    message: 'Please fill all password fields.',
                    type: SnackbarType.error);
                return;
              }
              if (next != confirm) {
                AppSnackbar.show(context,
                    message: 'New password and confirm password must match.',
                    type: SnackbarType.error);
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
                AppSnackbar.show(context,
                    message: 'Password changed successfully!',
                    type: SnackbarType.success);
              } catch (_) {
                if (!mounted) return;
                AppSnackbar.show(context,
                    message: 'Unable to change password right now.',
                    type: SnackbarType.error);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ── Help & support ────────────────────────────────────────────────────────

  void _showHelpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE5EAED),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                  color: PsychPalette.tealMist, shape: BoxShape.circle),
              child: const Icon(Icons.support_agent_rounded,
                  size: 30, color: PsychPalette.tealDeep),
            ),
            const SizedBox(height: 14),
            const Text('Help & Support',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: PsychPalette.ink)),
            const SizedBox(height: 6),
            const Text('Our team is available 24/7 to assist you.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: PsychPalette.inkSoft)),
            const SizedBox(height: 20),
            const _HelpOption(
                icon: Icons.email_outlined,
                label: 'Email Support',
                value: 'support@mindzep.com'),
            const SizedBox(height: 8),
            const _HelpOption(
                icon: Icons.phone_outlined,
                label: 'Phone Support',
                value: '+91 98765 43210'),
            const SizedBox(height: 8),
            const _HelpOption(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Live Chat',
                value: 'Available in-app'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Rate dialog ───────────────────────────────────────────────────────────

  void _showRatingDialog(BuildContext context) {
    int rating = 0;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Text('⭐', style: TextStyle(fontSize: 36)),
              SizedBox(height: 8),
              Text('Rate MindZep',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: PsychPalette.ink)),
            ],
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setDialogState(() => rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: PsychPalette.warning,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip',
                  style: TextStyle(color: PsychPalette.inkSoft)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    rating > 0 ? PsychPalette.teal : const Color(0xFFE5EAED),
                foregroundColor:
                    rating > 0 ? Colors.white : PsychPalette.inkFaint,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: rating == 0
                  ? null
                  : () {
                      Navigator.pop(context);
                      AppSnackbar.show(context,
                          message: 'Thank you for your feedback!',
                          type: SnackbarType.success);
                    },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small building blocks ─────────────────────────────────────────────────────

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CardTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: PsychPalette.tealDeep),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: PsychPalette.ink),
        ),
      ],
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 60, endIndent: 12, color: PsychPalette.line);
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: PsychPalette.ink)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: PsychPalette.inkFaint, size: 20),
      onTap: onTap,
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;
  const _SheetField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: PsychPalette.inkSoft)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: PsychPalette.scaffold,
              borderRadius: BorderRadius.circular(14)),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: PsychPalette.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFB6BFC5)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: PsychPalette.scaffold,
          borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscure,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: Color(0xFFB6BFC5)),
          border: InputBorder.none,
          isDense: true,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: PsychPalette.inkSoft),
          ),
        ),
      ),
    );
  }
}

class _HelpOption extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _HelpOption(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: PsychPalette.scaffold,
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
                color: PsychPalette.tealMist, shape: BoxShape.circle),
            child: Icon(icon, color: PsychPalette.tealDeep, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: PsychPalette.ink)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 12, color: PsychPalette.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
