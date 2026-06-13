import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'vm_dao.g.dart';

@DriftAccessor(tables: [VirtualMachines, RemoteSessions])
class VmDao extends DatabaseAccessor<AppDatabase> with _$VmDaoMixin {
  VmDao(AppDatabase db) : super(db);

  Stream<List<VirtualMachine>> watchAllVMs() => select(virtualMachines).watch();
  Stream<List<RemoteSession>> watchActiveSessions() => (select(remoteSessions)..where((t) => t.isActive.equals(1))).watch();

  Future<int> insertVM(VirtualMachinesCompanion entry) => into(virtualMachines).insert(entry);
  Future<int> insertSession(RemoteSessionsCompanion entry) => into(remoteSessions).insert(entry);
}
