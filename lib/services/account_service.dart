import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import '../database/database_helper.dart';

class AccountService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // إضافة حساب جديد
  Future<String> insertAccount(Account account) async {
    try {
      final Database db = await _databaseHelper.database;

      // إنشاء معرف فريد إذا لم يكن موجوداً
      final accountWithId =
          account.id == null
              ? account.copyWith(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
              )
              : account;

      final id = await db.insert(
        'accounts',
        accountWithId.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (id == 0) {
        throw 'فشل في إضافة الحساب في قاعدة البيانات';
      }

      return accountWithId.id!;
    } catch (e) {
      throw 'حدث خطأ أثناء إضافة الحساب: ${e.toString()}';
    }
  }

  // الحصول على جميع الحسابات
  Future<List<Account>> getAccounts() async {
    final Database db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');
    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  // الحصول على حساب محدد بواسطة المعرف
  Future<Account?> getAccount(String id) async {
    final Database db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    }
    return null;
  }

  // تحديث حساب
  Future<int> updateAccount(Account account) async {
    final Database db = await _databaseHelper.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  // حذف حساب
  Future<int> deleteAccount(String id) async {
    final Database db = await _databaseHelper.database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // الحصول على إجمالي الرصيد لجميع الحسابات
  Future<double> getTotalBalance() async {
    final Database db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(balance) as total FROM accounts',
    );
    return result.first['total'] == null
        ? 0.0
        : (result.first['total'] as num).toDouble();
  }

  // تحديث رصيد الحساب بعد إضافة معاملة
  Future<int> updateAccountBalance(String accountId, double amount) async {
    final Database db = await _databaseHelper.database;
    return await db.rawUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      [amount, accountId],
    );
  }
}
