import 'dart:async';
import 'package:flutter/foundation.dart';
import 'general_engine_client.dart';

class EngineRepository {
  static final EngineRepository instance = EngineRepository._internal();
  
  EngineRepository._internal() {
    _startPolling();
  }

  final ValueNotifier<List<GeneralEngineEntity>> allEntities = ValueNotifier([]);
  Timer? _pollTimer;

  // Type-specific getters
  List<GeneralEngineEntity> get events => 
      allEntities.value.where((e) => e.type == 'event').toList();
      
  List<GeneralEngineEntity> get tasks => 
      allEntities.value.where((e) => e.type == 'task').toList();
      
  List<GeneralEngineEntity> get habits => 
      allEntities.value.where((e) => e.type == 'habit').toList();
      
  List<GeneralEngineEntity> get metrics => 
      allEntities.value.where((e) => e.type == 'metric').toList();

  List<GeneralEngineEntity> get bankAccounts => 
      allEntities.value.where((e) => e.type == 'bank_account').toList();

  List<GeneralEngineEntity> get bankTransactions => 
      allEntities.value.where((e) => e.type == 'bank_transaction').toList();

  List<GeneralEngineEntity> get accountingCreds => 
      allEntities.value.where((e) => e.type == 'accounting_cred').toList();

  List<GeneralEngineEntity> get accountingDocs => 
      allEntities.value.where((e) => e.type == 'accounting_doc').toList();

  List<GeneralEngineEntity> get flashcardDecks => 
      allEntities.value.where((e) => e.type == 'flashcard_deck').toList();

  List<GeneralEngineEntity> get flashcards => 
      allEntities.value.where((e) => e.type == 'flashcard').toList();

  List<GeneralEngineEntity> get knowledgeTopics => 
      allEntities.value.where((e) => e.type == 'knowledge_topic').toList();

  List<GeneralEngineEntity> get movies => 
      allEntities.value.where((e) => e.type == 'media_movie').toList();

  List<GeneralEngineEntity> get musicTracks => 
      allEntities.value.where((e) => e.type == 'media_track').toList();

  List<GeneralEngineEntity> get playlists => 
      allEntities.value.where((e) => e.type == 'media_playlist').toList();

  List<GeneralEngineEntity> get youtubeVideos => 
      allEntities.value.where((e) => e.type == 'youtube_video').toList();

  List<GeneralEngineEntity> get smartDevices => 
      allEntities.value.where((e) => e.type == 'smart_device').toList();

  List<GeneralEngineEntity> get deviceSchedules => 
      allEntities.value.where((e) => e.type == 'device_schedule').toList();

  List<GeneralEngineEntity> get geofences => 
      allEntities.value.where((e) => e.type == 'geofence').toList();

  List<GeneralEngineEntity> get locationLogs => 
      allEntities.value.where((e) => e.type == 'location_log').toList();

  List<GeneralEngineEntity> get cloudBackups => 
      allEntities.value.where((e) => e.type == 'cloud_backup').toList();

  List<GeneralEngineEntity> get torrents => 
      allEntities.value.where((e) => e.type == 'torrent_item').toList();

  List<GeneralEngineEntity> get sharedFiles => 
      allEntities.value.where((e) => e.type == 'shared_file').toList();

  List<GeneralEngineEntity> get notifications => 
      allEntities.value.where((e) => e.type == 'notification').toList();

  void _startPolling() {
    // Initial fetch
    refresh();
    // Poll every 10 seconds for real-time multiplayer feel
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => refresh());
  }

  Future<void> refresh() async {
    final fetched = await GeneralEngineClient.getEntities();
    // Sort by updated_at descending
    fetched.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    allEntities.value = fetched;
  }

  Future<void> saveEntity(GeneralEngineEntity entity) async {
    final updated = await GeneralEngineClient.saveEntity(entity);
    if (updated != null) {
      // Optimistic local update
      final current = List<GeneralEngineEntity>.from(allEntities.value);
      final index = current.indexWhere((e) => e.id == updated.id);
      if (index >= 0) {
        current[index] = updated;
      } else {
        current.insert(0, updated);
      }
      allEntities.value = current;
    }
  }
  
  void dispose() {
    _pollTimer?.cancel();
    allEntities.dispose();
  }
}
