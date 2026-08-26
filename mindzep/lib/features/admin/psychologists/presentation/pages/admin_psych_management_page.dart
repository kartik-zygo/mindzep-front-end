import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/network/api_error_model.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../admin/data/models/admin_models.dart';
import '../../../../admin/data/repositories/admin_repository.dart';

class AdminPsychManagementPage extends StatefulWidget {
  const AdminPsychManagementPage({super.key});

  @override
  State<AdminPsychManagementPage> createState() =>
      _AdminPsychManagementPageState();
}

class _AdminPsychManagementPageState extends State<AdminPsychManagementPage> {
  static const _adminGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  late final AdminRepository _adminRepository;
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _activeFilter = 'All';
  String? _expandedId;

  bool _loading = true;
  String? _loadError;
  List<Map<String, dynamic>> _items = const [];

  static const _filters = ['All', 'Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    _adminRepository = sl<AdminRepository>();
    _loadPsychologists();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPsychologists() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final results = await _adminRepository.listPsychologists(page: 1, limit: 100);
      if (!mounted) return;
      setState(() { _items = results; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadError = e is ApiErrorModel ? e.message : 'Failed to load psychologists.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _readStr(Map<String, dynamic> m, List<String> keys, {String fallback = ''}) {
    for (final k in keys) {
      final v = m[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return fallback;
  }

  bool _readBool(Map<String, dynamic> m, String key, {bool fallback = true}) {
    final v = m[key];
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  String _id(Map<String, dynamic> m) => _readStr(m, ['_id', 'id', 'psychologistId']);

  List<Map<String, dynamic>> get _filtered {
    return _items.where((m) {
      final name = _readStr(m, ['name', 'fullName']);
      final spec = _readStr(m, ['specialization', 'specializations']);
      final matchSearch = _search.isEmpty ||
          name.toLowerCase().contains(_search.toLowerCase()) ||
          spec.toLowerCase().contains(_search.toLowerCase());
      final isActive = _readBool(m, 'isActive');
      final matchFilter = switch (_activeFilter) {
        'Active'   => isActive,
        'Inactive' => !isActive,
        _          => true,
      };
      return matchSearch && matchFilter;
    }).toList();
  }

  int get _inactiveCount => _items.where((m) => !_readBool(m, 'isActive')).length;

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePsychSheet(
        adminRepository: _adminRepository,
        onCreated: _loadPsychologists,
      ),
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> item) async {
    final id = _id(item);
    final isActive = _readBool(item, 'isActive');
    final name = _readStr(item, ['name', 'fullName'], fallback: 'Psychologist');
    try {
      if (isActive) {
        await _adminRepository.suspendPsychologist(id, SuspendEntityRequest(reason: 'Suspended by admin'));
      } else {
        await _adminRepository.activatePsychologist(id);
      }
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: isActive ? '$name has been suspended.' : '$name reactivated.',
        type: isActive ? SnackbarType.warning : SnackbarType.success,
      );
      _loadPsychologists();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiErrorModel ? e.message : 'Action failed.';
      AppSnackbar.show(context, message: msg, type: SnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(_loadError!, textAlign: TextAlign.center, style: AppTextStyles.body),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadPsychologists, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        backgroundColor: const Color(0xFFFF6B6B),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Therapist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: _adminGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Manage Therapists',
                              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_inactiveCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                              ),
                              child: Text(
                                '$_inactiveCount inactive',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) => setState(() => _search = v),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Search therapists...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final f = _filters[i];
                            final selected = _activeFilter == f;
                            return GestureDetector(
                              onTap: () => setState(() => _activeFilter = f),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected ? Colors.white : Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                                ),
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: selected ? const Color(0xFFFF6B6B) : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          itemCount: filtered.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
                child: Text(
                  '${filtered.length} therapists',
                  style: AppTextStyles.footnote.copyWith(color: AppColors.textSecondary),
                ),
              );
            }
            final item = filtered[i - 1];
            final id = _id(item);
            return _PsychCard(
              item: item,
              isExpanded: _expandedId == id,
              onTap: () => setState(() => _expandedId = _expandedId == id ? null : id),
              onToggleActive: () => _toggleActive(item),
              readStr: _readStr,
              readBool: _readBool,
            );
          },
        ),
      ),
    );
  }
}

// ─── Psychologist Card ────────────────────────────────────────────────────────

class _PsychCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;
  final String Function(Map<String, dynamic>, List<String>, {String fallback}) readStr;
  final bool Function(Map<String, dynamic>, String, {bool fallback}) readBool;

  const _PsychCard({
    required this.item,
    required this.isExpanded,
    required this.onTap,
    required this.onToggleActive,
    required this.readStr,
    required this.readBool,
  });

  @override
  Widget build(BuildContext context) {
    final userMap = item['user'] is Map<String, dynamic> ? item['user'] as Map<String, dynamic> : item;
final name = readStr(userMap, ['name', 'fullName'], fallback: 'Psychologist');
final email = readStr(userMap, ['email'], fallback: '');
final phone = readStr(userMap, ['phone'], fallback: '');
final avatarUrl = readStr(userMap, ['avatarUrl', 'profilePhoto', 'avatar'], fallback: '');
    final spec = readStr(item, ['specialization']);
    // final avatarUrl = readStr(item, ['avatarUrl', 'profilePhoto', 'avatar']);
    final bio = readStr(item, ['bio']);
    final credentials = readStr(item, ['credentials']);
    final yearsExp = item['yearsExperience'] ?? item['experienceYears'] ?? 0;
    final rate = item['ratePerMinute'] ?? 0;
    final totalSessions = item['totalSessions'] ?? 0;
    final rating = (item['ratingAverage'] ?? item['averageRating'] ?? 0).toDouble();
    final isActive = readBool(item, 'isActive');

    final specsRaw = item['specializations'];
    final specializations = specsRaw is List ? specsRaw.cast<String>() : <String>[];

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Row(
                children: [
                  AppAvatar(imageUrl: avatarUrl.isNotEmpty ? avatarUrl : null, radius: 26, initials: name[0]),
                  const SizedBox(width: AppDimensions.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTextStyles.subheadline.copyWith(fontWeight: FontWeight.w600)),
                        if (spec.isNotEmpty)
                          Text(spec, style: AppTextStyles.caption1.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _StatusPill(isActive: isActive),
                            if (rating > 0) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFF9500)),
                              const SizedBox(width: 2),
                              Text(rating.toStringAsFixed(1), style: AppTextStyles.caption1.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if ((totalSessions as num) > 0)
                        Text('$totalSessions', style: AppTextStyles.subheadline.copyWith(fontWeight: FontWeight.bold)),
                      Text('sessions', style: AppTextStyles.caption2.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textTertiary, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.surfaceSecondary),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MiniStat(label: 'Sessions', value: '$totalSessions'),
                      _MiniStat(label: 'Experience', value: '${yearsExp}y'),
                      _MiniStat(label: 'Rate', value: '₹$rate/min'),
                    ],
                  ),
                  if (credentials.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(credentials, style: AppTextStyles.caption1.copyWith(color: AppColors.textSecondary)),
                  ],
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(bio, style: AppTextStyles.caption1.copyWith(color: AppColors.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                  if (specializations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: specializations.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Text(s, style: AppTextStyles.caption2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500)),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(email, style: AppTextStyles.caption1.copyWith(color: AppColors.textSecondary)),
                  Text(phone, style: AppTextStyles.caption1.copyWith(color: AppColors.textSecondary)), 
                  SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: onToggleActive,
                    icon: Icon(isActive ? Icons.power_off_rounded : Icons.power_settings_new_rounded,
                        size: 16, color: isActive ? AppColors.error : AppColors.success),
                    label: Text(isActive ? 'Suspend' : 'Reactivate',
                        style: TextStyle(color: isActive ? AppColors.error : AppColors.success)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isActive ? AppColors.error : AppColors.success),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: AppTextStyles.caption2.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.subheadline
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: AppTextStyles.caption2
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Create Psychologist Sheet ────────────────────────────────────────────────

class _CreatePsychSheet extends StatefulWidget {
  final AdminRepository adminRepository;
  final VoidCallback onCreated;

  const _CreatePsychSheet({
    required this.adminRepository,
    required this.onCreated,
  });

  @override
  State<_CreatePsychSheet> createState() => _CreatePsychSheetState();
}

class _CreatePsychSheetState extends State<_CreatePsychSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _emailCtr = TextEditingController();
  final _phoneCtr = TextEditingController();
  final _credentialsCtr = TextEditingController();
  final _specializationCtr = TextEditingController();
  final _bioCtr = TextEditingController();
  final _languagesCtr = TextEditingController(text: 'English');
  final _yearsCtr = TextEditingController();
  final _rateCtr = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtr.dispose(); _emailCtr.dispose(); _phoneCtr.dispose();
    _credentialsCtr.dispose(); _specializationCtr.dispose(); _bioCtr.dispose();
    _languagesCtr.dispose(); _yearsCtr.dispose(); _rateCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final spec = _specializationCtr.text.trim();
      final langs = _languagesCtr.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final res = await widget.adminRepository.createPsychologist(
        CreatePsychologistRequest(
          name: _nameCtr.text.trim(),
          email: _emailCtr.text.trim(),
          phone: _phoneCtr.text.trim(),
          credentials: _credentialsCtr.text.trim(),
          specialization: spec,
          specializations: [spec],
          bio: _bioCtr.text.trim(),
          languages: langs.isEmpty ? ['English'] : langs,
          yearsExperience: int.tryParse(_yearsCtr.text.trim()) ?? 0,
          ratePerMinute: double.tryParse(_rateCtr.text.trim()) ?? 0,
        ),
      );
      if (!mounted) return;
      AppSnackbar.show(context, message: 'Psychologist created successfully.', type: SnackbarType.success);

      String tempPassword = '';
      if (res is Map<String, dynamic>) {
        final d = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
        if (d is Map<String, dynamic> && d['tempPassword'] is String) {
          tempPassword = d['tempPassword'] as String;
        }
      }

      if (tempPassword.isNotEmpty) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Temporary Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(tempPassword, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Copy or share this temporary password with the therapist.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: tempPassword));
                  AppSnackbar.show(context, message: 'Copied to clipboard', type: SnackbarType.success);
                },
                child: const Text('Copy'),
              ),
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
            ],
          ),
        );
      }

      Navigator.pop(context);
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiErrorModel ? e.message : 'Failed to create psychologist.';
      AppSnackbar.show(context, message: msg, type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Text('Add New Therapist', style: AppTextStyles.title3.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _Field(controller: _nameCtr, label: 'Full Name', hint: 'Dr. Jane Smith',
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                    _Field(controller: _emailCtr, label: 'Email', hint: 'dr.jane@example.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v?.trim().isEmpty ?? true) return 'Required';
                          if (!v!.contains('@')) return 'Invalid email';
                          return null;
                        }),
                    _Field(controller: _phoneCtr, label: 'Phone', hint: '+919876543210',
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                    _Field(controller: _credentialsCtr, label: 'Credentials', hint: 'PhD, M.Phil, RCI',
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                    _Field(controller: _specializationCtr, label: 'Primary Specialization', hint: 'Anxiety',
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                    _Field(controller: _bioCtr, label: 'Bio', hint: 'Brief professional bio...', maxLines: 3),
                    _Field(controller: _languagesCtr, label: 'Languages (comma-separated)', hint: 'English, Hindi'),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            controller: _yearsCtr,
                            label: 'Years of Experience',
                            hint: '5',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v?.trim().isEmpty ?? true) return 'Required';
                              if (int.tryParse(v!.trim()) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            controller: _rateCtr,
                            label: 'Rate per Minute (₹)',
                            hint: '20',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v?.trim().isEmpty ?? true) return 'Required';
                              if (double.tryParse(v!.trim()) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Create Psychologist', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: AppTextStyles.footnote.copyWith(color: AppColors.textSecondary),
          hintStyle: AppTextStyles.footnote.copyWith(color: AppColors.textTertiary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.surfaceSecondary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: BorderSide(color: AppColors.surfaceSecondary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
      ),
    );
  }
}
