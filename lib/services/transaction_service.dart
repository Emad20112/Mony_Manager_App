import 'package:sqflite/sqflite.dart' as sqflite;
import '../models/transaction.dart';
import '../database/database_helper.dart';

class TransactionService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // إضافة معاملة جديدة
  Future<String> insertTransaction(Transaction transaction) async {
    final sqflite.Database db = await _databaseHelper.database;
    print('TransactionService: Starting transaction insertion');
    print('Transaction details:');
    print('AccountId: ${transaction.accountId}');
    print('CategoryId: ${transaction.categoryId}');
    print('Amount: ${transaction.amount}');
    print('Type: ${transaction.type}');
    print('Transaction date: ${transaction.transactionDate}');

    // Convert transaction to map for debugging
    final transactionMap = transaction.toMap();
    print('Transaction map: $transactionMap');

    // بدء المعاملة لضمان تحديث الرصيد بشكل صحيح
    String newId = '';
    await db.transaction((txn) async {
      try {
        // إضافة المعاملة
        print('TransactionService: Inserting transaction into database');
        newId =
            (await txn.insert(
              'transactions',
              transaction.toMap(),
              conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
            )).toString();
        print('TransactionService: Transaction inserted with ID: $newId');

        if (newId.isEmpty) {
          throw Exception('Failed to insert transaction');
        }

        // تحديث رصيد الحساب
        double amountToUpdate = transaction.amount;
        if (transaction.type == TransactionType.expense) {
          // للمصروفات، نستخدم قيمة سالبة لتقليل الرصيد
          amountToUpdate = -amountToUpdate;
        }

        print('TransactionService: Updating account balance');
        print('Account ID: ${transaction.accountId}');
        print('Amount to update: $amountToUpdate');

        final int updatedRows = await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [amountToUpdate, transaction.accountId],
        );
        print('TransactionService: Updated rows: $updatedRows');

        if (updatedRows <= 0) {
          throw Exception('Failed to update account balance');
        }
      } catch (e) {
        // إذا حدث خطأ، سيتم التراجع عن المعاملة تلقائيًا
        print('TransactionService: Error in transaction: $e');
        rethrow;
      }
    });

    print(
      'TransactionService: Transaction completed successfully with ID: $newId',
    );
    return newId;
  }

  // الحصول على جميع المعاملات
  Future<List<Transaction>> getTransactions({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
    String? userId,
  }) async {
    final sqflite.Database db = await _databaseHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    // إضافة userId إلى الاستعلام (مطلوب)
    whereClause += 'userId = ?';
    whereArgs.add(userId ?? 'default_user');

    if (accountId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'accountId = ?';
      whereArgs.add(accountId);
    }

    if (categoryId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'categoryId = ?';
      whereArgs.add(categoryId);
    }

    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type.name);
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'transactionDate >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'transactionDate <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    List<Map<String, dynamic>> maps;
    if (whereClause.isNotEmpty) {
      maps = await db.query(
        'transactions',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'transactionDate DESC',
        limit: limit,
        offset: offset,
      );
    } else {
      maps = await db.query(
        'transactions',
        orderBy: 'transactionDate DESC',
        limit: limit,
        offset: offset,
      );
    }

    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  // الحصول على معاملة محددة بواسطة المعرف
  Future<Transaction?> getTransaction(String id, {String? userId}) async {
    final sqflite.Database db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId ?? 'default_user'],
    );
    if (maps.isNotEmpty) {
      return Transaction.fromMap(maps.first);
    }
    return null;
  }

  // تحديث معاملة
  Future<int> updateTransaction(Transaction transaction) async {
    final sqflite.Database db = await _databaseHelper.database;

    // الحصول على المعاملة القديمة لحساب الفرق في المبلغ
    if (transaction.id == null) {
      return 0; // لا يمكن تحديث معاملة بدون معرف
    }

    final oldTransaction = await getTransaction(transaction.id!);
    if (oldTransaction == null) {
      return 0; // لا يمكن تحديث معاملة غير موجودة
    }

    return await db.transaction((txn) async {
      // حساب الفرق في المبلغ للحساب القديم
      double oldAmount = oldTransaction.amount;
      if (oldTransaction.type == TransactionType.expense) {
        oldAmount = -oldAmount.abs();
      }

      // عكس تأثير المعاملة القديمة على الحساب
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [oldAmount, oldTransaction.accountId],
      );

      // حساب المبلغ الجديد للحساب الجديد
      double newAmount = transaction.amount;
      if (transaction.type == TransactionType.expense) {
        newAmount = -newAmount.abs();
      }

      // تطبيق تأثير المعاملة الجديدة على الحساب
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [newAmount, transaction.accountId],
      );

      // تحديث المعاملة نفسها
      return await txn.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    });
  }

  // حذف معاملة
  Future<int> deleteTransaction(String id) async {
    final sqflite.Database db = await _databaseHelper.database;

    // الحصول على المعاملة قبل حذفها لتحديث رصيد الحساب
    final transaction = await getTransaction(id);
    if (transaction == null) {
      return 0;
    }

    return await db.transaction((txn) async {
      // حساب المبلغ لتحديث الحساب
      double amountToUpdate = transaction.amount;
      if (transaction.type == TransactionType.expense) {
        // للمصروفات، نستخدم قيمة موجبة لزيادة الرصيد (عكس تأثير المصروف)
        amountToUpdate = amountToUpdate.abs();
      } else {
        // للإيرادات، نستخدم قيمة سالبة لتقليل الرصيد (عكس تأثير الإيراد)
        amountToUpdate = -amountToUpdate.abs();
      }

      // تحديث رصيد الحساب
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [amountToUpdate, transaction.accountId],
      );

      // حذف المعاملة
      return await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
    });
  }

  // الحصول على إجمالي المصروفات خلال فترة معينة
  Future<double> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    final sqflite.Database db = await _databaseHelper.database;

    String whereClause = "type = 'expense'";
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += ' AND transactionDate >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND transactionDate <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (categoryId != null) {
      whereClause += ' AND categoryId = ?';
      whereArgs.add(categoryId);
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE $whereClause',
      whereArgs,
    );

    return result.first['total'] == null
        ? 0.0
        : (result.first['total'] as num).toDouble();
  }

  // الحصول على إجمالي الإيرادات خلال فترة معينة
  Future<double> getTotalIncome({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    final sqflite.Database db = await _databaseHelper.database;

    String whereClause = "type = 'income'";
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += ' AND transactionDate >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND transactionDate <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (categoryId != null) {
      whereClause += ' AND categoryId = ?';
      whereArgs.add(categoryId);
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE $whereClause',
      whereArgs,
    );

    return result.first['total'] == null
        ? 0.0
        : (result.first['total'] as num).toDouble();
  }
}
