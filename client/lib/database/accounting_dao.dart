import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'accounting_dao.g.dart';

@DriftAccessor(tables: [AccountingCredentials, AccountingDocuments])
class AccountingDao extends DatabaseAccessor<AppDatabase> with _$AccountingDaoMixin {
  AccountingDao(AppDatabase db) : super(db);

  Stream<List<AccountingCredential>> watchAllCredentials() {
    return select(accountingCredentials).watch();
  }

  Stream<List<AccountingDocument>> watchAllDocuments() {
    return select(accountingDocuments).watch();
  }

  Future<int> insertCredential(AccountingCredentialsCompanion credential) {
    return into(accountingCredentials).insert(credential);
  }

  Future<int> insertDocument(AccountingDocumentsCompanion doc) {
    return into(accountingDocuments).insert(doc);
  }

  Future<void> markCredentialDirty(String id) async {
    await (update(accountingCredentials)..where((t) => t.id.equals(id))).write(
      const AccountingCredentialsCompanion(
        isDirty: Value(1),
      ),
    );
  }
}
