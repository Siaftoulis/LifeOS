import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'banking_dao.g.dart';

@DriftAccessor(tables: [BankAccounts, BankLedgers, BillLogs, BankingRollovers])
class BankingDao extends DatabaseAccessor<AppDatabase> with _$BankingDaoMixin {
  BankingDao(AppDatabase db) : super(db);

  Stream<List<BankAccount>> watchAllAccounts() {
    return select(bankAccounts).watch();
  }

  Stream<List<BankLedger>> watchRecentTransactions() {
    return (select(bankLedgers)
          ..orderBy([(t) => OrderingTerm(expression: t.dateTimestamp, mode: OrderingMode.desc)])
          ..limit(10))
        .watch();
  }

  Future<int> insertLedger(BankLedgersCompanion ledger) {
    return into(bankLedgers).insert(ledger);
  }

  Future<void> updateAccountBalance(String accountId, int newBalance) async {
    await (update(bankAccounts)..where((t) => t.id.equals(accountId))).write(
      BankAccountsCompanion(
        balanceCents: Value(newBalance),
        isDirty: const Value(1),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
