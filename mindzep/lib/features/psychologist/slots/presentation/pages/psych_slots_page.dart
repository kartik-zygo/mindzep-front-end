import 'package:flutter/material.dart';
import '../../../../../core/network/api_error_model.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/widgets/app_avatar.dart' show AvailabilityStatus;
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../injection/injection_container.dart';
import '../../../data/models/psychologist_models.dart';
import '../../../data/repositories/psychologist_repository.dart';
import '../../../shared/psych_ui.dart';

class PsychSlotsPage extends StatefulWidget {
  const PsychSlotsPage({super.key});

  @override
  State<PsychSlotsPage> createState() => _PsychSlotsPageState();
}

class _PsychSlotsPageState extends State<PsychSlotsPage> {
  late final PsychologistRepository _psychologistRepository;
  late DateTime _selectedDay;
  bool _isOnline = true;
  bool _loading = true;
  String? _errorMessage;
  final Set<String> _updatingSlotIds = <String>{};
  List<SlotEntity> _allSlots = const <SlotEntity>[];

  // 14-day strip starting from today so near-future slots are always reachable.
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _psychologistRepository = sl<PsychologistRepository>();
    final today = DateTime.now();
    _selectedDay = today;
    _weekDays = List.generate(14, (i) => today.add(Duration(days: i)));
    _loadSlots();
  }

  /// Ensures [day] is in the date strip and selects it.
  void _jumpToDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final lastDay = _weekDays.last;
    if (target.isAfter(lastDay)) {
      final diff = target.difference(today).inDays + 1;
      setState(() {
        _weekDays = List.generate(diff, (i) => today.add(Duration(days: i)));
        _selectedDay = target;
      });
    } else {
      setState(() => _selectedDay = target);
    }
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await _psychologistRepository.getMySlots(page: 1, limit: 100);

      var isOnline = _isOnline;
      try {
        final profile = await _psychologistRepository.getMyProfile();
        isOnline = profile.status == AvailabilityStatus.available;
      } catch (e) {
        debugPrint('[MindZep] PsychSlots profile fetch error (non-fatal): $e');
      }

      if (!mounted) return;

      setState(() {
        _isOnline = isOnline;
        _allSlots = response.items.map((item) => item.toEntity()).toList();
      });
    } catch (error) {
      debugPrint('[MindZep] PsychSlots load error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = _slotsLoadErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<SlotEntity> _slotsForDay(DateTime day) {
    return _allSlots.where((slot) {
      return slot.startTime.year == day.year &&
          slot.startTime.month == day.month &&
          slot.startTime.day == day.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<void> _setSlotBlockedState({
    required SlotEntity slot,
    required bool blocked,
  }) async {
    setState(() {
      _updatingSlotIds.add(slot.id);
    });

    try {
      await _psychologistRepository.bulkSlotAction(
        SlotBulkActionRequest(
          action: blocked ? 'block' : 'unblock',
          slotIds: <String>[slot.id],
        ),
      );
      await _loadSlots();
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: blocked ? 'Slot blocked.' : 'Slot unblocked.',
        type: SnackbarType.success,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Unable to update slot status.',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingSlotIds.remove(slot.id);
        });
      }
    }
  }

  Future<void> _deleteSlot(SlotEntity slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete slot?',
            style:
                TextStyle(fontWeight: FontWeight.w800, color: PsychPalette.ink)),
        content: const Text(
          'This availability slot will be permanently removed.',
          style: TextStyle(color: PsychPalette.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: PsychPalette.inkSoft)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PsychPalette.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _updatingSlotIds.add(slot.id);
    });

    try {
      await _psychologistRepository.deleteSlot(slot.id);
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Slot deleted successfully.',
        type: SnackbarType.success,
      );
      await _loadSlots();
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Unable to delete slot.',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingSlotIds.remove(slot.id);
        });
      }
    }
  }

  Future<void> _toggleAvailability() async {
    final next = !_isOnline;
    setState(() {
      _isOnline = next;
    });

    try {
      await _psychologistRepository.updateAvailability(
        AvailabilityUpdateRequest(status: next ? 'available' : 'offline'),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isOnline = !next;
      });
      AppSnackbar.show(
        context,
        message: 'Unable to update online status.',
        type: SnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = _slotsForDay(_selectedDay);
    final available =
        slots.where((s) => s.status == SlotStatus.available).length;
    final booked = slots.where((s) => s.status == SlotStatus.booked).length;

    return PsychScaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSlotDialog(context),
        backgroundColor: PsychPalette.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Slot',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          PsychGradientHeader(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Manage Slots',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _toggleAvailability,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 50,
                        height: 28,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _isOnline
                              ? PsychPalette.success
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(PsychRadii.pill),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          alignment: _isOnline
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 74,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _weekDays.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final d = _weekDays[i];
                      final isSel = d.year == _selectedDay.year &&
                          d.month == _selectedDay.month &&
                          d.day == _selectedDay.day;
                      final hasSlots = _slotsForDay(d).isNotEmpty;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDay = d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 52,
                          decoration: BoxDecoration(
                            color: isSel
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(
                                  alpha: isSel ? 0 : 0.22),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _dayAbbr(d),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSel
                                      ? PsychPalette.tealDeep
                                      : Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${d.day}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isSel
                                      ? PsychPalette.tealDeep
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: hasSlots
                                      ? (isSel
                                          ? PsychPalette.tealLight
                                          : Colors.white)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: PsychPalette.teal))
                : _errorMessage != null
                    ? _ErrorView(message: _errorMessage!, onRetry: _loadSlots)
                    : RefreshIndicator(
                        color: PsychPalette.teal,
                        onRefresh: _loadSlots,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PsychCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: PsychPalette.tealMist,
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: const Icon(
                                          Icons.calendar_month_rounded,
                                          color: PsychPalette.tealDeep,
                                          size: 23),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _fullDayLabel(_selectedDay),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: PsychPalette.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${slots.length} slots · $available available · $booked booked',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: PsychPalette.inkSoft,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (slots.isEmpty)
                                PsychEmptyState(
                                  icon: Icons.event_available_rounded,
                                  title: 'No slots for this day',
                                  subtitle:
                                      'Add availability so patients can book a session with you.',
                                  action: PsychPrimaryButton(
                                    label: 'Add a Slot',
                                    icon: Icons.add_rounded,
                                    expand: false,
                                    onPressed: () => _showAddSlotDialog(context),
                                  ),
                                )
                              else ...[
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 10),
                                  child: Text(
                                    'AVAILABILITY',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: PsychPalette.inkFaint,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                ...slots.asMap().entries.map(
                                      (e) => PsychFadeIn(
                                        delayMs: (e.key * 40).clamp(0, 240),
                                        child: _SlotTile(
                                          slot: e.value,
                                          busy: _updatingSlotIds
                                              .contains(e.value.id),
                                          onToggleBlocked:
                                              e.value.status == SlotStatus.booked
                                                  ? null
                                                  : (blocked) =>
                                                      _setSlotBlockedState(
                                                        slot: e.value,
                                                        blocked: blocked,
                                                      ),
                                          onDelete:
                                              e.value.status == SlotStatus.booked
                                                  ? null
                                                  : () => _deleteSlot(e.value),
                                        ),
                                      ),
                                    ),
                              ],
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _dayAbbr(DateTime d) {
    const abbrs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return abbrs[d.weekday - 1];
  }

  String _fullDayLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_dayAbbr(d)}, ${months[d.month - 1]} ${d.day}';
  }

  String _slotsLoadErrorMessage(Object error) {
    if (error is ApiErrorModel) {
      final msg = error.message.trim();
      if (msg.isNotEmpty) return msg;
    }
    return 'Unable to load slots right now.';
  }

  int _todMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay _addMinutes(TimeOfDay t, int delta) {
    final total = (_todMinutes(t) + delta).clamp(0, 24 * 60 - 1);
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  String _formatDurationLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Future<void> _showAddSlotDialog(BuildContext context) async {
    final now = DateTime.now();
    final isToday = _selectedDay.year == now.year &&
        _selectedDay.month == now.month &&
        _selectedDay.day == now.day;
    final defaultTime = isToday
        ? TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)))
        : const TimeOfDay(hour: 9, minute: 0);

    TimeOfDay startTod = defaultTime;
    TimeOfDay endTod = _addMinutes(defaultTime, 60);
    final selectedTypes = <String>{'video', 'audio'};
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final durationMin = _todMinutes(endTod) - _todMinutes(startTod);
          final valid = durationMin >= 5 && durationMin <= 1440;
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Add Slot · ${_fullDayLabel(_selectedDay)}',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: PsychPalette.ink)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set an availability window — patients can book any part of it.',
                  style: TextStyle(
                      color: PsychPalette.inkSoft, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerTile(
                        label: 'Start',
                        value: startTod.format(dialogContext),
                        onTap: () async {
                          final picked = await showTimePicker(
                              context: dialogContext, initialTime: startTod);
                          if (picked == null) return;
                          setDialogState(() {
                            startTod = picked;
                            if (_todMinutes(endTod) <= _todMinutes(startTod)) {
                              endTod = _addMinutes(startTod, 30);
                            }
                          });
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 18, color: PsychPalette.inkFaint),
                    ),
                    Expanded(
                      child: _TimePickerTile(
                        label: 'End',
                        value: endTod.format(dialogContext),
                        onTap: () async {
                          final picked = await showTimePicker(
                              context: dialogContext, initialTime: endTod);
                          if (picked == null) return;
                          setDialogState(() => endTod = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: valid
                        ? PsychPalette.tealMist
                        : PsychPalette.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(valid ? Icons.timelapse_rounded : Icons.error_outline_rounded,
                          size: 17,
                          color:
                              valid ? PsychPalette.tealDeep : PsychPalette.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          valid
                              ? 'Window length · ${_formatDurationLabel(durationMin)}'
                              : 'End must be after start (5 min – 24 h).',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: valid
                                ? PsychPalette.tealDeep
                                : PsychPalette.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('SESSION TYPES',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: PsychPalette.inkFaint,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ('video', Icons.videocam_rounded, 'Video'),
                    ('audio', Icons.phone_rounded, 'Audio'),
                    ('chat', Icons.chat_bubble_rounded, 'Chat'),
                  ].map((t) {
                    final sel = selectedTypes.contains(t.$1);
                    return GestureDetector(
                      onTap: () => setDialogState(() {
                        if (sel) {
                          if (selectedTypes.length > 1) {
                            selectedTypes.remove(t.$1);
                          }
                        } else {
                          selectedTypes.add(t.$1);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: sel ? PsychPalette.brandGradient : null,
                          color: sel ? null : PsychPalette.scaffold,
                          borderRadius:
                              BorderRadius.circular(PsychRadii.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.$2,
                                size: 14,
                                color: sel
                                    ? Colors.white
                                    : PsychPalette.inkSoft),
                            const SizedBox(width: 5),
                            Text(t.$3,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: sel
                                      ? Colors.white
                                      : PsychPalette.inkSoft,
                                )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    isSubmitting ? null : () => Navigator.pop(dialogContext),
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
                onPressed: isSubmitting || !valid
                    ? null
                    : () async {
                        final startTime = DateTime(
                          _selectedDay.year,
                          _selectedDay.month,
                          _selectedDay.day,
                          startTod.hour,
                          startTod.minute,
                        );

                        if (!startTime.isAfter(DateTime.now())) {
                          AppSnackbar.show(
                            this.context,
                            message:
                                'Slot time must be in the future. Please select a later time.',
                            type: SnackbarType.error,
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        try {
                          await _psychologistRepository.createSlot(
                            SlotCreateRequest(
                              startTime: startTime,
                              durationMinutes: durationMin,
                              sessionTypes: selectedTypes.toList(),
                            ),
                          );
                          if (!mounted) return;
                          Navigator.pop(dialogContext);
                          AppSnackbar.show(
                            this.context,
                            message: 'Slot added successfully.',
                            type: SnackbarType.success,
                          );
                          await _loadSlots();
                        } catch (e) {
                          debugPrint(
                              '[MindZep] PsychSlots createSlot error: $e');
                          if (!mounted) return;
                          final isConflict =
                              e is ApiErrorModel && e.statusCode == 409;
                          final msg = e is ApiErrorModel
                              ? e.message
                              : 'Unable to add slot right now.';

                          if (isConflict) {
                            Navigator.pop(dialogContext);
                            _jumpToDay(startTime);
                            AppSnackbar.show(
                              this.context,
                              message: msg,
                              type: SnackbarType.error,
                            );
                            await _loadSlots();
                          } else {
                            AppSnackbar.show(
                              this.context,
                              message: msg,
                              type: SnackbarType.error,
                            );
                            setDialogState(() => isSubmitting = false);
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Slot'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: PsychPalette.inkFaint, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: PsychPalette.inkSoft),
            ),
            const SizedBox(height: 16),
            PsychPrimaryButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final SlotEntity slot;
  final bool busy;
  final ValueChanged<bool>? onToggleBlocked;
  final VoidCallback? onDelete;

  const _SlotTile({
    required this.slot,
    required this.busy,
    required this.onToggleBlocked,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final (statusColor, bgColor, statusLabel) = _statusStyle(slot.status);

    return PsychCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: PsychRadii.tile,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
                color: statusColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.access_time_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_hhmm(slot.startTime)} · ${slot.durationMinutes} min',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: PsychPalette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                PsychStatusPill(label: statusLabel, color: statusColor),
              ],
            ),
          ),
          if (busy)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: PsychPalette.teal),
            )
          else if (slot.status == SlotStatus.available)
            Switch(
              value: true,
              onChanged: (_) => onToggleBlocked?.call(true),
              activeColor: PsychPalette.teal,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else if (slot.status == SlotStatus.blocked)
            Switch(
              value: false,
              onChanged: (_) => onToggleBlocked?.call(false),
              activeColor: PsychPalette.teal,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: PsychPalette.tealMist,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lock_rounded,
                  color: PsychPalette.tealDeep, size: 16),
            ),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PsychPalette.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: PsychPalette.danger, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, Color, String) _statusStyle(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return (PsychPalette.success, const Color(0xFFE7F9F0), 'Available');
      case SlotStatus.booked:
        return (PsychPalette.teal, PsychPalette.tealMist, 'Booked');
      case SlotStatus.blocked:
        return (PsychPalette.danger, const Color(0xFFFFECEC), 'Blocked');
    }
  }

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimePickerTile(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: PsychPalette.scaffold,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PsychPalette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: PsychPalette.inkFaint)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: PsychPalette.tealDeep),
                const SizedBox(width: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PsychPalette.ink)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
