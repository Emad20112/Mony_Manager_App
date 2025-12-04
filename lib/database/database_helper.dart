import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// import '../services/encryption_service.dart'; // Not used in standard sqflite

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'money_manager_encrypted.db');

    // Get encryption key (not used in standard sqflite)
    // final encryptionKey = await EncryptionService.getEncryptionKey();

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // جدول المستخدمين
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        photoUrl TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        settings TEXT
      )
    ''');

    // جدول الحسابات
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        currency TEXT NOT NULL,
        balance REAL NOT NULL,
        description TEXT,
        userId TEXT NOT NULL,
        isArchived INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        icon TEXT,
        colorValue INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // جدول الفئات
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        colorValue INTEGER NOT NULL,
        userId TEXT NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        parentId TEXT,
        budgetLimit REAL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (parentId) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // جدول المعاملات
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        accountId TEXT NOT NULL,
        userId TEXT NOT NULL,
        transactionDate TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        toAccountId TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        metadata TEXT,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        recurringRuleId TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE,
        FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (toAccountId) REFERENCES accounts (id) ON DELETE SET NULL
      )
    ''');

    // جدول الأهداف المالية
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL,
        targetDate INTEGER NOT NULL,
        note TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        contributions TEXT
      )
    ''');

    // جدول المعاملات المتكررة
    await db.execute('''
      CREATE TABLE recurring_transactions (
        id TEXT PRIMARY KEY,
        accountId TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        frequency TEXT NOT NULL,
        interval INTEGER NOT NULL DEFAULT 1,
        startDate TEXT NOT NULL,
        endDate TEXT,
        maxOccurrences INTEGER,
        status TEXT NOT NULL DEFAULT 'active',
        userId TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        lastExecuted TEXT,
        executedCount INTEGER NOT NULL DEFAULT 0,
        metadata TEXT,
        FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // جدول الميزانيات
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // إنشاء الفهارس
    await db.execute(
      'CREATE INDEX idx_transactions_user ON transactions(userId)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_account ON transactions(accountId)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON transactions(categoryId)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(transactionDate)',
    );
    await db.execute('CREATE INDEX idx_accounts_user ON accounts(userId)');
    await db.execute('CREATE INDEX idx_categories_user ON categories(userId)');
    await db.execute(
      'CREATE INDEX idx_budgets_category ON budgets(category_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      // إضافة جدول الأهداف المالية عند الترقية من الإصدار 1 إلى الإصدار 2
      await db.execute('''
        CREATE TABLE goals (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          targetAmount REAL NOT NULL,
          currentAmount REAL NOT NULL,
          targetDate INTEGER NOT NULL,
          note TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          contributions TEXT
        )
      ''');
    }

    if (oldVersion < 3 && newVersion >= 3) {
      // إضافة جدول المعاملات المتكررة عند الترقية من الإصدار 2 إلى الإصدار 3
      await db.execute('''
        CREATE TABLE recurring_transactions (
          id TEXT PRIMARY KEY,
          accountId TEXT NOT NULL,
          categoryId TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT NOT NULL,
          frequency TEXT NOT NULL,
          interval INTEGER NOT NULL DEFAULT 1,
          startDate TEXT NOT NULL,
          endDate TEXT,
          maxOccurrences INTEGER,
          status TEXT NOT NULL DEFAULT 'active',
          userId TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          lastExecuted TEXT,
          executedCount INTEGER NOT NULL DEFAULT 0,
          metadata TEXT,
          FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE,
          FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 4 && newVersion >= 4) {
      // إضافة جدول الميزانيات عند الترقية من الإصدار 3 إلى الإصدار 4
      await db.execute('''
        CREATE TABLE budgets (
          id TEXT PRIMARY KEY,
          category_id TEXT NOT NULL,
          amount REAL NOT NULL,
          period TEXT NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
        )
      ''');

      // إضافة فهرس لجدول الميزانيات
      await db.execute(
        'CREATE INDEX idx_budgets_category ON budgets(category_id)',
      );
    }
  }

  Future<void> deleteDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'money_manager_encrypted.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // Helper methods for transactions
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }
}
