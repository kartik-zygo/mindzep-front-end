class AppDateUtils {
  AppDateUtils._();

  static String greeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, $name';
    if (hour < 17) return 'Good afternoon, $name';
    return 'Good evening, $name';
  }

  static String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  static String formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  static String formatDateTime(DateTime date) =>
      '${formatDate(date)} · ${formatTime(date)}';

  static String formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String formatDurationLong(int seconds) {
    final totalMinutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (totalMinutes == 0) return '$remainingSeconds sec';
    if (remainingSeconds == 0) return '$totalMinutes min';
    return '$totalMinutes min $remainingSeconds sec';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static bool isTomorrow(DateTime date) =>
      isSameDay(date, DateTime.now().add(const Duration(days: 1)));

  static String relativeDay(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    return formatDate(date);
  }

  static List<DateTime> next30Days() {
    final today = DateTime.now();
    return List.generate(
      30,
      (i) => DateTime(today.year, today.month, today.day + i),
    );
  }

  static bool isWithinBookingWindow(DateTime date) {
    final today = DateTime.now();
    final maxDate = DateTime(today.year, today.month + 1, today.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return !normalizedDate.isBefore(normalizedToday) &&
        !normalizedDate.isAfter(maxDate);
  }
}
