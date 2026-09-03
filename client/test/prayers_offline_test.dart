import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
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

    final headers = chrysostom.sections.map((s) => s.header).toList();
    expect(headers.any((h) => h.contains('Αντίφωνον')), isTrue);
    expect(headers.any((h) => h.contains('Ειρηνικά') || h.contains('Έναρξις')), isTrue);
    expect(headers.any((h) => h.contains('Αναφορά') || h.contains('Μετανοίας') || h.contains('Απόλυσις')), isTrue);
  });

  test('offline assets/prayers contains psalter, nt, synaxarion, and lectionary', () async {
    final psalterFile = File('assets/prayers/psalter.json');
    expect(psalterFile.existsSync(), isTrue);
    final psalterJson = jsonDecode(psalterFile.readAsStringSync()) as Map<String, dynamic>;
    final kathismata = psalterJson['kathismata'] as List;
    expect(kathismata.length, equals(20));

    final ntFile = File('assets/prayers/nt.json');
    expect(ntFile.existsSync(), isTrue);
    final ntJson = jsonDecode(ntFile.readAsStringSync()) as Map<String, dynamic>;
    final books = ntJson['books'] as List;
    expect(books.length, equals(27));

    final synaxarionFile = File('assets/prayers/synaxarion.json');
    expect(synaxarionFile.existsSync(), isTrue);
    final synaxarionJson = jsonDecode(synaxarionFile.readAsStringSync()) as Map<String, dynamic>;
    final days = synaxarionJson['days'] as Map<String, dynamic>;
    expect(days.containsKey('09-03'), isTrue);

    final lectionaryFile = File('assets/prayers/lectionary.json');
    expect(lectionaryFile.existsSync(), isTrue);
    final lectionaryJson = jsonDecode(lectionaryFile.readAsStringSync()) as Map<String, dynamic>;
    final readings = lectionaryJson['readings'] as Map<String, dynamic>;
    expect(readings.containsKey('09-03'), isTrue);
  });
}
