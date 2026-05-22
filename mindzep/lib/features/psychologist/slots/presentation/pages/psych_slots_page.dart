import 'package:flutter/material.dart';
import '../../../../../core/network/api_error_model.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../injection/injection_container.dart';
import '../../../data/models/psychologist_models.dart';
import '../../../data/repositories/psychologist_repository.dart';

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
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    // Extend strip if the target day is beyond current range.
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
      // Keep this request conservative to avoid backend-side limit validation failures.
      final response = await _psychologistRepository.getMySlots(page: 1, limit: 100);

      var isOnline = _isOnline;
      try {
        final profile = await _psychologistRepository.getMyProfile();
        isOnline = profile.status == AvailabilityStatus.available;
      } catch (e) {
        // Slots should still render even if profile status endpoint fails.
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
    final available = slots.where((s) => s.status == SlotStatus.available).length;
    final booked = slots.where((s) => s.status == SlotStatus.booked).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          // ── Teal Gradient Header ──────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + online toggle
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Manage Slots',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          _isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _toggleAvailability,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48, height: 26,
                            decoration: BoxDecoration(
                              color: _isOnline
                                  ? const Color(0xFF34C759).withOpacity(0.9)
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: _isOnline ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                width: 22, height: 22,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Horizontal 7-day strip
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _weekDays.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final d = _weekDays[i];
                          final isSel = d.day == _selectedDay.day &&
                              d.month == _selectedDay.month;
                          final daySlots = _slotsForDay(d);
                          final hasSlots = daySlots.isNotEmpty;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDay = d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 50,
                              decoration: BoxDecoration(
                                color: isSel ? Colors.white : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _dayAbbr(d),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isSel ? const Color(0xFF30B0C7) : Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${d.day}',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? const Color(0xFF30B0C7) : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    width: 6, height: 6,
                                    decoration: BoxDecoration(
                                      color: hasSlots
                                          ? (isSel ? const Color(0xFF30B0C7) : Colors.white.withOpacity(0.7))
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
            ),
          ),

          // ── Body ──────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF8E8E93)),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadSlots,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSlots,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Summary card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6F8FA),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF30B0C7), size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _fullDayLabel(_selectedDay),
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                                          ),
                                          Text(
                                            '${slots.length} slots · $available available · $booked booked',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _showAddSlotDialog(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text('+ Add', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (slots.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 48),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 60, height: 60,
                                          decoration: const BoxDecoration(color: Color(0xFFE6F8FA), shape: BoxShape.circle),
                                          child: const Icon(Icons.event_available_rounded, color: Color(0xFF30B0C7), size: 28),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text('No slots for this day', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3C3C3C))),
                                        const SizedBox(height: 4),
                                        const Text('Tap "+ Add" to add availability', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                                      ],
                                    ),
                                  ),
                                )
                              else ...[
                                const Text(
                                  'AVAILABLE SLOTS',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8E8E93), letterSpacing: 0.8),
                                ),
                                const SizedBox(height: 10),
                                ...slots.map(
                                  (slot) => _SlotTile(
                                    slot: slot,
                                    busy: _updatingSlotIds.contains(slot.id),
                                    onToggleBlocked: slot.status == SlotStatus.booked
                                        ? null
                                        : (blocked) => _setSlotBlockedState(
                                              slot: slot,
                                              blocked: blocked,
                                            ),
                                    onDelete: slot.status == SlotStatus.booked
                                        ? null
                                        : () => _deleteSlot(slot),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 80),
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
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${_dayAbbr(d)}, ${months[d.month - 1]} ${d.day}';
  }

  String _slotsLoadErrorMessage(Object error) {
    if (error is ApiErrorModel) {
      final msg = error.message.trim();
      if (msg.isNotEmpty) {
        return msg;
      }
    }
    return 'Unable to load slots right now.';
  }

  Future<void> _showAddSlotDialog(BuildContext context) async {
    // Default to 1 hour from now when the selected day is today,
    // otherwise default to 09:00 on future days.
    final now = DateTime.now();
    final isToday = _selectedDay.year == now.year &&
        _selectedDay.month == now.month &&
        _selectedDay.day == now.day;
    final defaultTime = isToday
        ? TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)))
        : const TimeOfDay(hour: 9, minute: 0);

    TimeOfDay selectedTime = defaultTime;
    String durationText = '45';
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Add Slot'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: dialogContext,
                      initialTime: selectedTime,
                    );
                    if (picked == null) return;
                    setDialogState(() {
                      selectedTime = picked;
                    });
                  },
                  icon: const Icon(Icons.access_time_rounded),
                  label: Text('Time: ${selectedTime.format(dialogContext)}'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: durationText,
                  onChanged: (v) => durationText = v,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final duration = int.tryParse(durationText.trim());
                        if (duration == null || duration <= 0) {
                          AppSnackbar.show(
                            this.context,
                            message: 'Enter a valid duration.',
                            type: SnackbarType.error,
                          );
                          return;
                        }

                        final startTime = DateTime(
                          _selectedDay.year,
                          _selectedDay.month,
                          _selectedDay.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        // Backend requires startTime to be strictly in the future.
                        if (!startTime.isAfter(DateTime.now())) {
                          AppSnackbar.show(
                            this.context,
                            message: 'Slot time must be in the future. Please select a later time.',
                            type: SnackbarType.error,
                          );
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                        });

                        try {
                          await _psychologistRepository.createSlot(
                            SlotCreateRequest(
                              startTime: startTime,
                              durationMinutes: duration,
                              sessionTypes: const <String>['video'],
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
                          debugPrint('[MindZep] PsychSlots createSlot error: $e');
                          if (!mounted) return;
                          final isConflict =
                              e is ApiErrorModel && e.statusCode == 409;
                          final msg = e is ApiErrorModel
                              ? e.message
                              : 'Unable to add slot right now.';

                          if (isConflict) {
                            // Close dialog, jump to the conflicting day, and
                            // refresh so the existing overlapping slot is visible.
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
                            setDialogState(() {
                              isSubmitting = false;
                            });
                          }
                        }
                      },
                child: const Text('Add Slot'),
              ),
            ],
          );
        },
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
    Color statusColor;
    String statusLabel;
    Color bgColor;
    switch (slot.status) {
      case SlotStatus.available:
        statusColor = const Color(0xFF34C759);
        bgColor = const Color(0xFFE8FFF1);
        statusLabel = 'Available';
        break;
      case SlotStatus.booked:
        statusColor = const Color(0xFF30B0C7);
        bgColor = const Color(0xFFE6F8FA);
        statusLabel = 'Booked';
        break;
      case SlotStatus.blocked:
        statusColor = const Color(0xFFFF3B30);
        bgColor = const Color(0xFFFFF0F0);
        statusLabel = 'Blocked';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 44,
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 14),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.access_time_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')} · ${slot.durationMinutes} min',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ],
            ),
          ),
          if (busy)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (slot.status == SlotStatus.available)
            Switch(
              value: true,
              onChanged: (_) => onToggleBlocked?.call(true),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else if (slot.status == SlotStatus.blocked)
            Switch(
              value: false,
              onChanged: (_) => onToggleBlocked?.call(false),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFE6F8FA), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lock_rounded, color: Color(0xFF30B0C7), size: 16),
            ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF3B30), size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


