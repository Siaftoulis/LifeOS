import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../../auth_service.dart';

const expenseCategories = ['Groceries', 'Allowance', 'Bills', 'Other'];

String creatorId() =>
    AuthService.instance.currentUser.value?.username ?? 'panospds';

final ValueNotifier<int> pointsTick = ValueNotifier(0);

String fmtEuro(double v) =>
    NumberFormat.currency(locale: 'de_DE', symbol: '€').format(v);

String monthLabel() => DateFormat('MMMM yyyy').format(DateTime.now());

String isoDate(String? raw) {
  final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
  if (raw == null || raw.isEmpty) return now;
  for (final f in [
    'dd/MM/yyyy',
    'dd-MM-yyyy',
    'dd.MM.yyyy',
    'dd/MM/yy',
    'dd-MM-yy',
    'yyyy-MM-dd'
  ]) {
    try {
      return DateFormat('yyyy-MM-dd').format(DateFormat(f).parse(raw));
    } catch (_) {}
  }
  return now;
}

String displayDate(String raw) {
  final d = DateTime.tryParse(raw);
  if (d != null) return DateFormat('MMM dd, yyyy').format(d);
  return raw;
}
