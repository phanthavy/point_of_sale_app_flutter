String formatNumber(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String formatKip(int amount) => '${formatNumber(amount)} ₭';

String _twoDigits(int n) => n.toString().padLeft(2, '0');

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatDate(DateTime d) =>
    '${_twoDigits(d.day)}/${_twoDigits(d.month)}/${d.year}';

String formatTime(DateTime d) =>
    '${_twoDigits(d.hour)}:${_twoDigits(d.minute)}';

String formatDateTime(DateTime d) =>
    '${_twoDigits(d.day)}/${_twoDigits(d.month)}/${d.year} '
    '${_twoDigits(d.hour)}:${_twoDigits(d.minute)}';
