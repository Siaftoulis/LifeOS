import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/core/repositories/built_in_prayers.dart';
import 'package:lifeos_client/core/repositories/prayer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('offline prayers_core.json contains all complete services including Divine Liturgy', () async {
    final file = File('assets/prayers_core.json');
    expect(file.existsSync(), isTrue, reason: 'assets/prayers_core.json must exist');

    final jsonStr = file.readAsStringSync();
    final Map<String, dynamic> data = jsonDecode(jsonStr);

    expect(data.containsKey('divine_liturgy_chrysostom'), isTrue);
    expect(data.containsKey('divine_liturgy_basil'), isTrue);
    expect(data.containsKey('matins'), isTrue);
    expect(data.containsKey('vespers'), isTrue);

    final chrysostom = PrayerServiceModel.fromJson(Map<String, dynamic>.from(data['divine_liturgy_chrysostom']));
    expect(chrysostom.title, contains('Χρυσοστόμου'));
    expect(chrysostom.sections.length, greaterThanOrEqualTo(20));

    // Verify key liturgical prayers exist in sections
    final headers = chrysostom.sections.map((s) => s.header).toList();
    expect(headers.any((h) => h.contains('Αντίφωνον')), isTrue);
    expect(headers.any((h) => h.contains('Ειρηνικά') || h.contains('Έναρξις')), isTrue);
    expect(headers.any((h) => h.contains('Αναφορά') || h.contains('Μετανοίας') || h.contains('Απόλυσις')), isTrue);
  });
}
