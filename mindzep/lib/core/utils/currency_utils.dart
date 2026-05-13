class CurrencyUtils {
  CurrencyUtils._();

  static String formatRupees(double amount) {
    if (amount == amount.truncate()) {
      return '₹${amount.toInt()}';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }

  static String formatRatePerMin(double rate) => '₹${rate.toInt()}/min';

  static double calculateCallCost({
    required int totalSeconds,
    required int freeMinutes,
    required double ratePerMinute,
  }) {
    final freeSeconds = freeMinutes * 60;
    if (totalSeconds <= freeSeconds) return 0.0;
    final billedSeconds = totalSeconds - freeSeconds;
    return (billedSeconds / 60.0) * ratePerMinute;
  }

  static int billedSeconds({
    required int totalSeconds,
    required int freeMinutes,
  }) {
    final freeSeconds = freeMinutes * 60;
    return totalSeconds > freeSeconds ? totalSeconds - freeSeconds : 0;
  }

  static String callBillingText({
    required int totalSeconds,
    required int freeMinutes,
    required double ratePerMinute,
  }) {
    final freeSeconds = freeMinutes * 60;
    if (totalSeconds < freeSeconds) {
      final remaining = ((freeSeconds - totalSeconds) / 60).ceil();
      return '$remaining min free remaining';
    }
    final cost = calculateCallCost(
      totalSeconds: totalSeconds,
      freeMinutes: freeMinutes,
      ratePerMinute: ratePerMinute,
    );
    return 'Billing started – ${formatRupees(cost)} accrued';
  }
}
