import 'package:flutter/material.dart';

extension StringExtensions on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get initials {
    final parts = trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  bool get isValidEmail {
    return RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(trim());
  }
}

extension DateTimeExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  bool get isPast => isBefore(DateTime.now());

  bool get isFuture => isAfter(DateTime.now());

  DateTime get dateOnly => DateTime(year, month, day);
}

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  void unfocus() => FocusScope.of(this).unfocus();
}

extension DoubleExtensions on double {
  String get toRupees {
    if (this == truncate()) return '₹${toInt()}';
    return '₹${toStringAsFixed(2)}';
  }
}

extension IntExtensions on int {
  String get toRupees => '₹$this';

  String get toMinSec {
    final m = (this ~/ 60).toString().padLeft(2, '0');
    final s = (this % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
