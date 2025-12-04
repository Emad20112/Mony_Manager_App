import 'package:sqflite/sqflite.dart' as sql;
import '../database/database_helper.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final DatabaseHelper _databaseHelper;

  TransactionRepository(this._databaseHelper);

  Future<List<Transaction>> getTransactions(
    String userId, {
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    int? limit,
    int? offset,
  }) async {
    final db = await _databaseHelper.database;

    String whereClause = 'userId = ?';
    List<dynamic> whereArgs = [userId];

    if (accountId != null) {
      whereClause += ' AND accountId = ?';
      whereArgs.add(accountId);
    }

    if (categoryId != null) {
      whereClause += ' AND categoryId = ?';
      whereArgs.add(categoryId);
    }

    if (startDate != null) {
      whereClause += ' AND transactionDate >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND transactionDate <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type.toString().split('.').last);
    }

    // Transaction model does not define a status field currently.

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'transactionDate DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  Future<Transaction?> getTransaction(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Transaction.fromMap(maps.first);
  }

  Future<void> insertTransaction(Transaction transaction) async {
    await _databaseHelper.transaction((sql.Transaction txn) async {
      // إدخال المعاملة
      await txn.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );

      // تحديث رصيد الحساب
      if (transaction.type == TransactionType.income) {
        await _updateAccountBalance(
          txn,
          transaction.accountId,
          transaction.amount,
        );
      } else if (transaction.type == TransactionType.expense) {
        await _updateAccountBalance(
          txn,
          transaction.accountId,
          -transaction.amount,
        );
      }
    });
  }

  Future<void> updateTransaction(
    Transaction oldTransaction,
    Transaction newTransaction,
  ) async {
    await _databaseHelper.transaction((sql.Transaction txn) async {
      // إلغاء تأثير المعاملة القديمة
      if (oldTransaction.type == TransactionType.income) {
        await _updateAccountBalance(
          txn,
          oldTransaction.accountId,
          -oldTransaction.amount,
        );
      } else if (oldTransaction.type == TransactionType.expense) {
        await _updateAccountBalance(
          txn,
          oldTransaction.accountId,
          oldTransaction.amount,
        );
      }

      // تطبيق تأثير المعاملة الجديدة
      if (newTransaction.type == TransactionType.income) {
        await _updateAccountBalance(
          txn,
          newTransaction.accountId,
          newTransaction.amount,
        );
      } else if (newTransaction.type == TransactionType.expense) {
        await _updateAccountBalance(
          txn,
          newTransaction.accountId,
          -newTransaction.amount,
        );
      }

      // تحديث المعاملة
      await txn.update(
        'transactions',
        newTransaction.toMap(),
        where: 'id = ?',
        whereArgs: [oldTransaction.id],
      );
    });
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await _databaseHelper.transaction((sql.Transaction txn) async {
      // إلغاء تأثير المعاملة على الرصيد
      if (transaction.type == TransactionType.income) {
        await _updateAccountBalance(
          txn,
          transaction.accountId,
          -transaction.amount,
        );
      } else if (transaction.type == TransactionType.expense) {
        await _updateAccountBalance(
          txn,
          transaction.accountId,
          transaction.amount,
        );
      }

      // حذف المعاملة
      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    });
  }

  Future<void> _updateAccountBalance(
    sql.Transaction txn,
    String accountId,
    double amount,
  ) async {
    await txn.rawUpdate(
      '''
      UPDATE accounts
      SET balance = balance + ?,
          updatedAt = ?
      WHERE id = ?
    ''',
      [amount, DateTime.now().toIso8601String(), accountId],
    );
  }

  Future<Map<String, double>> getCategoryTotals(
    String accountId,
    DateTime startDate,
    DateTime endDate, {
    TransactionType? type,
  }) async {
    final db = await _databaseHelper.database;

    String whereClause = '''
      accountId = ? 
      AND transactionDate >= ? 
      AND transactionDate <= ?
    ''';
    List<dynamic> whereArgs = [
      accountId,
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ];

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type.toString().split('.').last);
    }

    try {
      print('🔄 Getting category totals with query params:');
      print('  - accountId: $accountId');
      print('  - startDate: $startDate');
      print('  - endDate: $endDate');
      print('  - type: $type');

      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT categoryId, SUM(amount) as total
        FROM transactions
        WHERE $whereClause
        GROUP BY categoryId
      ''', whereArgs);

      final Map<String, double> totals = {};
      for (var row in results) {
        if (row['categoryId'] != null) {
          final categoryId = row['categoryId'] as String;
          final total = row['total'] as double? ?? 0.0;
          totals[categoryId] = total;
          print('  - Category $categoryId: $total');
        }
      }

      print('✅ Got totals for ${totals.length} categories');
      return totals;
    } catch (e) {
      print('❌ Error getting category totals: $e');
      // Return empty map instead of throwing to avoid crashing the UI
      return {};
    }
  }

  Future<double> getAccountTransactionsTotal(
    String accountId,
    DateTime startDate,
    DateTime endDate, {
    TransactionType? type,
  }) async {
    final db = await _databaseHelper.database;

    String whereClause = '''
      accountId = ? 
      AND transactionDate >= ? 
      AND transactionDate <= ?
    ''';
    List<dynamic> whereArgs = [
      accountId,
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ];

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type.toString().split('.').last);
    }

    try {
      print('🔄 Getting account transactions total with query params:');
      print('  - accountId: $accountId');
      print('  - startDate: $startDate');
      print('  - endDate: $endDate');
      print('  - type: $type');

      final result = await db.rawQuery('''
        SELECT SUM(amount) as total
        FROM transactions
        WHERE $whereClause
      ''', whereArgs);

      final total = result.first['total'] as double? ?? 0.0;
      print('✅ Account total: $total');
      return total;
    } catch (e) {
      print('❌ Error calculating account total: $e');
      return 0.0;
    }
  }
}
