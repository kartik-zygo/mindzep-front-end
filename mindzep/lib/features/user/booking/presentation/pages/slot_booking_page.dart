import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/network/api_error_model.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/utils/currency_utils.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../psychologist/data/repositories/psychologist_repository.dart';

class SlotBookingPage extends StatefulWidget {
  final PsychologistEntity psychologist;

  const SlotBookingPage({super.key, required this.psychologist});

  @override
  State<SlotBookingPage> createState() => _SlotBookingPageState();
}

class _SlotBookingPageState extends State<SlotBookingPage> {
  late final PsychologistRepository _psychologistRepository;

  late DateTime _selectedDate;
  SlotEntity? _selectedSlot;
  String _sessionType = 'video'; // video | audio
  bool _isLoadingSlots = true;
  String? _slotErrorMessage;
  List<SlotEntity> _availableSlots = const <SlotEntity>[];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _psychologistRepository = sl<PsychologistRepository>();
    _loadSlots();
  }

  List<DateTime> get _dates => AppDateUtils.next30Days();

  PsychologistEntity get p => widget.psychologist;

  Future<void> _loadSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _slotErrorMessage = null;
    });

    try {
      final models = await _psychologistRepository.getPublicSlotsByPsychologist(
        widget.psychologist.id,
        date: _formatApiDate(_selectedDate),
      );

      final selectedSession =
          _sessionType == 'audio' ? SessionType.audio : SessionType.video;

      final mapped = models
          .map((model) => model.toEntity())
          .where((slot) => slot.status == SlotStatus.available)
          .where((slot) => slot.sessionTypes.contains(selectedSession))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      if (!mounted) return;
      setState(() {
        _availableSlots = mapped;
        if (_selectedSlot != null &&
            !_availableSlots.any((slot) => slot.id == _selectedSlot!.id)) {
          _selectedSlot = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _slotErrorMessage = error is ApiErrorModel
            ? error.message
            : 'Unable to load slots for this day.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
      }
    }
  }

  String _formatApiDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Session'),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildPsychHeader(),
                _buildSessionTypeSelector(),
                _buildDateStrip(),
                _buildSlotGrid(),
              ],
            ),
          ),
          _buildBookButton(context),
        ],
      ),
    );
  }

  Widget _buildPsychHeader() {
    return AppCard(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: p.avatarUrl,
            radius: 28,
            availabilityStatus: p.status,
            showStatusDot: true,
            initials: _initials(p.name),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: AppTextStyles.headline
                        .copyWith(color: AppColors.textPrimary)),
                Text(p.specialization,
                    style: AppTextStyles.subheadline
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  CurrencyUtils.formatRatePerMin(p.ratePerMinute),
                  style: AppTextStyles.footnote.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Session Type',
              style: AppTextStyles.headline
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.paddingS),
          Row(
            children: [
              _SessionTypeCard(
                label: 'Video Call',
                icon: Icons.videocam_rounded,
                isSelected: _sessionType == 'video',
                onTap: () {
                  if (_sessionType == 'video') return;
                  setState(() {
                    _sessionType = 'video';
                    _selectedSlot = null;
                  });
                  _loadSlots();
                },
              ),
              const SizedBox(width: AppDimensions.paddingM),
              _SessionTypeCard(
                label: 'Audio Call',
                icon: Icons.phone_rounded,
                isSelected: _sessionType == 'audio',
                onTap: () {
                  if (_sessionType == 'audio') return;
                  setState(() {
                    _sessionType = 'audio';
                    _selectedSlot = null;
                  });
                  _loadSlots();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.paddingM,
              AppDimensions.paddingL, AppDimensions.paddingM, AppDimensions.paddingS),
          child: Text('Select Date',
              style: AppTextStyles.headline
                  .copyWith(color: AppColors.textPrimary)),
        ),
        SizedBox(
          height: 76,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM),
            itemCount: _dates.length,
            itemBuilder: (_, i) {
              final date = _dates[i];
              final isSelected =
                  AppDateUtils.isSameDay(date, _selectedDate);
              return GestureDetector(
                onTap: () {
                  if (AppDateUtils.isSameDay(date, _selectedDate)) return;
                  setState(() {
                    _selectedDate = date;
                    _selectedSlot = null;
                  });
                  _loadSlots();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  margin: const EdgeInsets.only(right: AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayAbbr(date),
                        style: AppTextStyles.caption2.copyWith(
                          color: isSelected
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: AppTextStyles.headline.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _monthAbbr(date),
                        style: AppTextStyles.caption2.copyWith(
                          color: isSelected
                              ? Colors.white70
                              : AppColors.textSecondary,
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
    );
  }

  Widget _buildSlotGrid() {
    if (_isLoadingSlots) {
      return const Padding(
        padding: EdgeInsets.all(AppDimensions.paddingM),
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_slotErrorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _slotErrorMessage!,
                style: AppTextStyles.footnote
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.paddingS),
              TextButton(
                onPressed: _loadSlots,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final slots = _availableSlots;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available Slots',
              style: AppTextStyles.headline
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.paddingS),
          if (slots.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'No available $_sessionType slots on this date.',
                style: AppTextStyles.footnote
                    .copyWith(color: AppColors.textSecondary),
              ),
            )
          else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppDimensions.paddingS,
              crossAxisSpacing: AppDimensions.paddingS,
              childAspectRatio: 2.1,
            ),
            itemCount: slots.length,
            itemBuilder: (_, i) {
              final slot = slots[i];
              final isSelected = _selectedSlot?.id == slot.id;
              final isAvailable = slot.status == SlotStatus.available;
              return GestureDetector(
                onTap: isAvailable
                    ? () {
                        setState(() => _selectedSlot = slot);
                        _openBookingSheet(slot);
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isAvailable
                            ? AppColors.surface
                            : AppColors.background,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusS),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : isAvailable
                              ? AppColors.border
                              : AppColors.border.withOpacity(0.4),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}',
                          style: AppTextStyles.caption1.copyWith(
                            color: isSelected
                                ? Colors.white
                                : isAvailable
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                            decoration: !isAvailable
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${slot.durationMinutes}m',
                          style: AppTextStyles.caption2.copyWith(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Legend
          const SizedBox(height: AppDimensions.paddingM),
          Row(
            children: [
              _LegendItem(
                  color: AppColors.primary, label: 'Selected'),
              const SizedBox(width: AppDimensions.paddingM),
              _LegendItem(
                  color: AppColors.surface, label: 'Available'),
              const SizedBox(width: AppDimensions.paddingM),
              _LegendItem(
                  color: AppColors.background, label: 'Booked'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: AppButton(
          label: _selectedSlot == null
              ? 'Select a Slot to Continue'
              : 'Choose Time & Duration',
          onPressed:
              _selectedSlot != null ? () => _openBookingSheet(_selectedSlot!) : null,
        ),
      ),
    );
  }

  /// Opens the sub-range picker for the chosen availability window. The user
  /// selects a start time within the window and a duration; on confirm we
  /// forward the exact `[startTime, durationMinutes]` to the payment page.
  Future<void> _openBookingSheet(SlotEntity slot) async {
    final result = await showModalBottomSheet<(DateTime, int)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingConfigSheet(
        slot: slot,
        psychologist: p,
        sessionType: _sessionType,
      ),
    );
    if (result == null || !mounted) return;
    context.push(
      RouteNames.payment,
      extra: {
        'psychologist': p,
        'slot': slot,
        'sessionType': _sessionType,
        'bookedStartTime': result.$1,
        'bookedDurationMinutes': result.$2,
      },
    );
  }

  String _dayAbbr(DateTime d) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[d.weekday % 7];
  }

  String _monthAbbr(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[d.month - 1];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SessionTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SessionTypeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.subheadline.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption2
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Booking sub-range picker ────────────────────────────────────────────────

/// Lets the user pick a start time + duration *inside* an availability window.
/// Returns the chosen `(startTime, durationMinutes)` via `Navigator.pop`.
class _BookingConfigSheet extends StatefulWidget {
  final SlotEntity slot;
  final PsychologistEntity psychologist;
  final String sessionType;

  const _BookingConfigSheet({
    required this.slot,
    required this.psychologist,
    required this.sessionType,
  });

  @override
  State<_BookingConfigSheet> createState() => _BookingConfigSheetState();
}

class _BookingConfigSheetState extends State<_BookingConfigSheet> {
  late DateTime _start;
  late int _duration;

  SlotEntity get _slot => widget.slot;
  DateTime get _windowEnd => _slot.endTime;

  /// Minutes available from the current start to the end of the window.
  int get _remaining => _windowEnd.difference(_start).inMinutes;

  /// Full window length (max possible duration when starting at window start).
  int get _windowMinutes => _slot.durationMinutes;

  @override
  void initState() {
    super.initState();
    _start = _slot.startTime;
    // Default to a comfortable 30 min (or the whole window if it's shorter).
    _duration = _windowMinutes < 30 ? _windowMinutes : 30;
  }

  // Full booked duration billed at the psychologist's rate — no free minutes
  // (the session is prepaid in full, with no per-minute charge during the call).
  double get _cost => CurrencyUtils.calculateCallCost(
        totalSeconds: _duration * 60,
        freeMinutes: 0,
        ratePerMinute: widget.psychologist.ratePerMinute,
      );

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
      helpText: 'Session start time',
    );
    if (picked == null) return;
    final minStart = _slot.startTime;
    final maxStart = _windowEnd.subtract(const Duration(minutes: 5));
    var candidate = DateTime(minStart.year, minStart.month, minStart.day,
        picked.hour, picked.minute);
    if (candidate.isBefore(minStart)) candidate = minStart;
    if (candidate.isAfter(maxStart)) candidate = maxStart;
    setState(() {
      _start = candidate;
      if (_duration > _remaining) _duration = _remaining;
      if (_duration < 5) _duration = _remaining;
    });
  }

  void _setDuration(int minutes) {
    setState(() => _duration = minutes.clamp(5, _remaining));
  }

  @override
  Widget build(BuildContext context) {
    final end = _start.add(Duration(minutes: _duration));
    final quick = [15, 30, 45, 60].where((d) => d <= _remaining).toList();
    final canIncrease = _duration + 5 <= _remaining;
    final canDecrease = _duration - 5 >= 5;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Customise your session',
                style: AppTextStyles.title3
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(
              'Book any part of this availability window.',
              style: AppTextStyles.subheadline
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            // Window banner
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Available ${_hhmm(_slot.startTime)}–${_hhmm(_windowEnd)} · $_windowMinutes min',
                      style: AppTextStyles.footnote.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Start time
            _FieldLabel('START TIME'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickStart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(_hhmm(_start),
                        style: AppTextStyles.title3
                            .copyWith(color: AppColors.textPrimary)),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Duration stepper
            Row(
              children: [
                _FieldLabel('DURATION'),
                const Spacer(),
                Text('$_duration min',
                    style: AppTextStyles.subheadline.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  enabled: canDecrease,
                  onTap: () => _setDuration(_duration - 5),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _formatDuration(_duration),
                      style: AppTextStyles.title2
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  enabled: canIncrease,
                  onTap: () => _setDuration(_duration + 5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...quick.map((d) => _DurationChip(
                      label: '$d min',
                      selected: _duration == d,
                      onTap: () => _setDuration(d),
                    )),
                _DurationChip(
                  label: 'Full ($_remaining)',
                  selected: _duration == _remaining,
                  onTap: () => _setDuration(_remaining),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Summary
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_hhmm(_start)} – ${_hhmm(end)}',
                            style: AppTextStyles.headline
                                .copyWith(color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('Estimated charge',
                            style: AppTextStyles.caption1.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    _cost <= 0 ? 'Free' : CurrencyUtils.formatRupees(_cost),
                    style: AppTextStyles.title3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: _cost <= 0
                  ? 'Proceed to Payment'
                  : 'Proceed · ${CurrencyUtils.formatRupees(_cost)}',
              onPressed: () => Navigator.pop(context, (_start, _duration)),
            ),
          ],
        ),
      ),
    );
  }

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '$m min';
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption2.copyWith(
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Icon(icon,
            color: enabled ? AppColors.primary : AppColors.textTertiary,
            size: 24),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DurationChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: AppTextStyles.footnote.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

