import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2);
final _monthDay = DateFormat('MM.dd');
final _dateTime = DateFormat('yyyy.MM.dd HH:mm');
final _month = DateFormat('MM月');

String formatCurrency(double value) => _currency.format(value);
String formatMonthDay(DateTime value) => _monthDay.format(value);
String formatDateTime(DateTime value) => _dateTime.format(value);
String formatMonth(DateTime value) => _month.format(value);

int daysSince(DateTime value) {
  final now = DateTime.now();
  final start = DateTime(value.year, value.month, value.day);
  final today = DateTime(now.year, now.month, now.day);
  return today.difference(start).inDays;
}

String formatWaitingLabel(DateTime value) {
  final days = daysSince(value);
  if (days <= 0) return '今天刚记';
  if (days == 1) return '已等 1 天';
  return '已等 $days 天';
}

String formatRelativeDecision(DateTime value) {
  final days = daysSince(value);
  if (days <= 0) return '今天';
  if (days == 1) return '昨天';
  if (days < 7) return '$days 天前';
  return formatMonthDay(value);
}
