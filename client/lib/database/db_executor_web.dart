// ponytail: browser SQLite via sqlite3.wasm + drift worker; data is then
// filled from the daemon through the existing sync layer (cloud-first).
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

Future<QueryExecutor> openDbExecutor() async {
  final result = await WasmDatabase.open(
    databaseName: 'lifeos',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );
  return result.resolvedExecutor;
}
