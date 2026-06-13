// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banking_dao.dart';

// ignore_for_file: type=lint
mixin _$BankingDaoMixin on DatabaseAccessor<AppDatabase> {
  $BankAccountsTable get bankAccounts => attachedDatabase.bankAccounts;
  $BankLedgersTable get bankLedgers => attachedDatabase.bankLedgers;
  $BillLogsTable get billLogs => attachedDatabase.billLogs;
  $BankingRolloversTable get bankingRollovers =>
      attachedDatabase.bankingRollovers;
  BankingDaoManager get managers => BankingDaoManager(this);
}

class BankingDaoManager {
  final _$BankingDaoMixin _db;
  BankingDaoManager(this._db);
  $$BankAccountsTableTableManager get bankAccounts =>
      $$BankAccountsTableTableManager(_db.attachedDatabase, _db.bankAccounts);
  $$BankLedgersTableTableManager get bankLedgers =>
      $$BankLedgersTableTableManager(_db.attachedDatabase, _db.bankLedgers);
  $$BillLogsTableTableManager get billLogs =>
      $$BillLogsTableTableManager(_db.attachedDatabase, _db.billLogs);
  $$BankingRolloversTableTableManager get bankingRollovers =>
      $$BankingRolloversTableTableManager(
          _db.attachedDatabase, _db.bankingRollovers);
}
