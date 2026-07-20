import 'package:drift/drift.dart';

@DataClassName('AccountingCredential')
class AccountingCredentials extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get label => text()(); // e.g., 'Taxisnet', 'AFM', 'AMKA'
  BlobColumn get encryptedUsername => blob().nullable()(); // AES-GCM encrypted
  BlobColumn get encryptedPassword => blob().nullable()(); // AES-GCM encrypted
  IntColumn get updatedAt => integer()(); // Unix millisecond timestamp
  IntColumn get syncedAt => integer().nullable()(); // Nullable sync timestamp
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AccountingDocument')
class AccountingDocuments extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get title => text()(); // e.g., 'ID Card Scan 2026'
  TextColumn get encryptedFilepath => text()(); // Encrypted local relative path
  TextColumn get fileExtension => text()(); // e.g., 'pdf', 'png'
  IntColumn get updatedAt => integer()(); // Unix millisecond timestamp
  IntColumn get syncedAt => integer().nullable()(); // Nullable sync timestamp
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BankAccount')
class BankAccounts extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get name => text()(); // e.g., 'Primary Eurobank', 'Bills Saver'
  IntColumn get balanceCents => integer()(); // Account balance in cents
  IntColumn get updatedAt => integer()(); // Unix millisecond timestamp
  IntColumn get syncedAt => integer().nullable()(); // Nullable sync timestamp
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BankLedger')
class BankLedgers extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get accountId => text().customConstraint('NOT NULL REFERENCES bank_accounts(id)')();
  IntColumn get amountCents => integer()(); // Signed integer cents (positive = credit, negative = debit)
  TextColumn get transactionType => text()(); // e.g., 'Groceries', 'Allowance', 'Bills'
  IntColumn get dateTimestamp => integer()(); // Transaction date stamp
  TextColumn get description => text().nullable()(); // Optional description
  IntColumn get updatedAt => integer()(); // Unix millisecond timestamp
  IntColumn get syncedAt => integer().nullable()(); // Nullable sync timestamp
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BillLog')
class BillLogs extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get provider => text()(); // e.g., 'DEI', 'Cosmote'
  IntColumn get amountCents => integer()(); // Bill cost in cents
  IntColumn get dueDate => integer()(); // Unix timestamp due date
  IntColumn get updatedAt => integer()(); // Unix millisecond timestamp

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BankingRollover')
class BankingRollovers extends Table {
  TextColumn get key => text()(); // e.g., 'bills_carry_over'
  IntColumn get surplusCents => integer()(); // Surplus amount in cents
  IntColumn get updatedAt => integer()(); // Unix millisecond timestamp

  @override
  Set<Column> get primaryKey => {key};
}

