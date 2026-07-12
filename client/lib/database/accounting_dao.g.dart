// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounting_dao.dart';

// ignore_for_file: type=lint
mixin _$AccountingDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountingCredentialsTable get accountingCredentials =>
      attachedDatabase.accountingCredentials;
  $AccountingDocumentsTable get accountingDocuments =>
      attachedDatabase.accountingDocuments;
  AccountingDaoManager get managers => AccountingDaoManager(this);
}

class AccountingDaoManager {
  final _$AccountingDaoMixin _db;
  AccountingDaoManager(this._db);
  $$AccountingCredentialsTableTableManager get accountingCredentials =>
      $$AccountingCredentialsTableTableManager(
          _db.attachedDatabase, _db.accountingCredentials);
  $$AccountingDocumentsTableTableManager get accountingDocuments =>
      $$AccountingDocumentsTableTableManager(
          _db.attachedDatabase, _db.accountingDocuments);
}
