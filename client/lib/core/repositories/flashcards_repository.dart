import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../api_client.dart';
import '../telemetry/telemetry_reporter.dart';
import 'base_daemon_repository.dart';
import 'models/domain_models.dart';

/// Flashcard decks (`GET /api/v1/flashcards/decks`), created via POST.
class FlashcardsRepository extends DaemonRepository {
  static final FlashcardsRepository instance = FlashcardsRepository._();

  FlashcardsRepository._();

  final ValueNotifier<List<FlashcardDeck>> decks = ValueNotifier(const []);

  @override
  Future<void> load() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/flashcards/decks');
      if (res is List) {
        decks.value = res
            .whereType<Map>()
            .map((m) => FlashcardDeck.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> createDeck(String name) async {
    try {
      await ApiClient.instance
          .postDaemon('/api/v1/flashcards/decks/create', {'name': name});
      await load();
      TelemetryReporter.instance.track('flashcards', 'deck_created', {'name': name});
    } catch (_) {}
  }
}
