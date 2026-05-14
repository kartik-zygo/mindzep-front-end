import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/mock/mock_data.dart';

class PsychSlotsPage extends StatefulWidget {
  const PsychSlotsPage({super.key});

  @override
  State<PsychSlotsPage> createState() => _PsychSlotsPageState();
}

class _PsychSlotsPageState extends State<PsychSlotsPage> {
  late DateTime _selectedDay;
  bool _isOnline = true;

  // Generate 7-day strip starting from today
  
  late final List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDay = today;
    _weekDays = List.generate(7, (i) => today.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final slots = MockData.getSlotsForPsychologist('p001', _selectedDay);
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
                          onTap: () => setState(() => _isOnline = !_isOnline),
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
                          final daySlots = MockData.getSlotsForPsychologist('p001', d);
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
            child: SingleChildScrollView(
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
                    ...slots.map((slot) => _SlotTile(slot: slot)),
                  ],
                  const SizedBox(height: 80),
                ],
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

  void _showAddSlotDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Slot'),
        content: const Text('Slot management coming soon. You will be able to add/block slots from here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF30B0C7))),
          ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatefulWidget {
  final SlotEntity slot;
  const _SlotTile({required this.slot});

  @override
  State<_SlotTile> createState() => _SlotTileState();
}

class _SlotTileState extends State<_SlotTile> {
  late SlotStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.slot.status;
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    Color bgColor;
    switch (_status) {
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
                  '${widget.slot.startTime.hour.toString().padLeft(2, '0')}:${widget.slot.startTime.minute.toString().padLeft(2, '0')} · ${widget.slot.durationMinutes} min',
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
          if (_status == SlotStatus.available)
            Switch(
              value: true,
              onChanged: (v) => setState(() => _status = SlotStatus.blocked),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else if (_status == SlotStatus.blocked)
            Switch(
              value: false,
              onChanged: (v) => setState(() => _status = SlotStatus.available),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFE6F8FA), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lock_rounded, color: Color(0xFF30B0C7), size: 16),
            ),
        ],
      ),
    );
  }
}


