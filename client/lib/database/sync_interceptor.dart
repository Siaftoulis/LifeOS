import 'package:drift/drift.dart';

/// A Drift model change-interceptor listener to automatically generate and append deltas (SYNC-002)
class SyncInterceptor extends QueryInterceptor {
  final QueryExecutor _inner;

  SyncInterceptor(this._inner);

  @override
  QueryExecutor get inner => _inner;

  @override
  Future<int> runInsert(QueryExecutor executor, String statement, List<Object?> args) async {
    final result = await super.runInsert(executor, statement, args);
    // Automatically generate and append deltas for insert operations
    await _recordDelta(executor, statement, args, 'INSERT');
    return result;
  }

  @override
  Future<int> runUpdate(QueryExecutor executor, String statement, List<Object?> args) async {
    final result = await super.runUpdate(executor, statement, args);
    // Automatically generate and append deltas for update operations
    await _recordDelta(executor, statement, args, 'UPDATE');
    return result;
  }

  @override
  Future<int> runDelete(QueryExecutor executor, String statement, List<Object?> args) async {
    final result = await super.runDelete(executor, statement, args);
    // Automatically generate and append deltas for delete operations
    await _recordDelta(executor, statement, args, 'DELETE');
    return result;
  }

  Future<void> _recordDelta(QueryExecutor executor, String statement, List<Object?> args, String operation) async {
    // Basic heuristics to ignore internal tables
    if (statement.contains('sync_queue') || statement.contains('system_users')) {
      return;
    }
    
    try {
      final targetTable = _extractTableName(statement);
      if (targetTable != null) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        // Naive delta append - typically handled by a robust parser or SQLite triggers
        await super.runInsert(
          executor,
          'INSERT INTO sync_queue (id, target_table, record_id, field_name, client_updated_at) VALUES (?, ?, ?, ?, ?)',
          ['sq-\$ts-\$targetTable', targetTable, 'unknown', operation, ts]
        );
      }
    } catch (e) {
      // Absorb delta logging errors safely
    }
  }

  String? _extractTableName(String statement) {
    final stmt = statement.toLowerCase();
    if (stmt.contains('into ')) {
      final parts = stmt.split('into ');
      if (parts.length > 1) {
        return parts[1].split(' ').first;
      }
    } else if (stmt.contains('update ')) {
      final parts = stmt.split('update ');
      if (parts.length > 1) {
        return parts[1].split(' ').first;
      }
    } else if (stmt.contains('from ')) {
      final parts = stmt.split('from ');
      if (parts.length > 1) {
        return parts[1].split(' ').first;
      }
    }
    return null;
  }
}
