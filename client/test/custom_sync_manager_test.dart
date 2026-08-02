import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/api_client.dart';
import 'package:lifeos_client/core/telemetry_service.dart';
import 'package:lifeos_client/core/websocket_service.dart';
import 'package:lifeos_client/database/custom_sync_manager.dart';

class MockWebSocketService implements WebSocketService {
  final List<Map<String, dynamic>> sentMessages = [];
  @override
  String get serverUrl => 'ws://localhost';
  @override
  void Function(Map<String, dynamic> data) get onMessageReceived => (_) {};

  @override
  void connect() {}
  @override
  void send(Map<String, dynamic> data) {
    sentMessages.add(data);
  }
  @override
  void dispose() {}
}

class MockDb {
  bool shouldThrow = false;
  List<Map<String, dynamic>> mockData = [];

  MockSelectResult customSelect(String sql) {
    if (shouldThrow) {
      throw Exception('DB error during sync');
    }
    return MockSelectResult(mockData);
  }
}

class MockSelectResult {
  final List<Map<String, dynamic>> _data;
  MockSelectResult(this._data);
  Future<List<MockRow>> get() async {
    return _data.map((d) => MockRow(d)).toList();
  }
}

class MockRow {
  final Map<String, dynamic> data;
  MockRow(this.data);
}

class MockTelemetryService extends TelemetryService {
  final List<String> events = [];

  MockTelemetryService() : super(webSocketService: MockWebSocketService());

  @override
  void logSyncSuccess({required int durationMs, required int itemsCount}) {
    events.add('sync_success:items=$itemsCount');
  }

  @override
  void logSyncRetry({required int attempt, required int nextDelayMs}) {
    events.add('sync_retry:attempt=$attempt,delay=$nextDelayMs');
  }

  @override
  void logSyncFailed({required String error, required int attempt}) {
    events.add('sync_failed:attempt=$attempt');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CustomSyncManager successful sync flow updates status and logs telemetry', () async {
    final mockWs = MockWebSocketService();
    final mockDb = MockDb();
    mockDb.mockData = [
      {'id': '1', 'name': 'Read 20 mins', 'type': 'habit', 'goal_value': 1, 'updated_at': 100}
    ];
    final mockTelemetry = MockTelemetryService();

    final syncManager = CustomSyncManager(
      ApiClient(baseUrl: 'http://localhost', daemonUrl: 'http://localhost'),
      mockDb,
      webSocketService: mockWs,
      telemetryService: mockTelemetry,
    );

    expect(syncManager.status, equals(SyncStatus.idle));

    await syncManager.runSyncCycle();

    expect(syncManager.status, equals(SyncStatus.synced));
    expect(mockWs.sentMessages.length, equals(1));
    expect(mockWs.sentMessages.first['type'], equals('sync_push'));
    expect(mockTelemetry.events, contains('sync_success:items=1'));

    syncManager.dispose();
  });

  test('CustomSyncManager failure triggers retry status and backoff telemetry', () async {
    final mockWs = MockWebSocketService();
    final mockDb = MockDb();
    mockDb.shouldThrow = true;
    final mockTelemetry = MockTelemetryService();

    final syncManager = CustomSyncManager(
      ApiClient(baseUrl: 'http://localhost', daemonUrl: 'http://localhost'),
      mockDb,
      webSocketService: mockWs,
      telemetryService: mockTelemetry,
      maxRetries: 2,
      initialDelayMs: 50,
      backoffMultiplier: 2.0,
    );

    await syncManager.runSyncCycle();

    expect(syncManager.status, equals(SyncStatus.retrying));
    expect(mockTelemetry.events, contains('sync_retry:attempt=1,delay=50'));

    syncManager.dispose();
  });
}
