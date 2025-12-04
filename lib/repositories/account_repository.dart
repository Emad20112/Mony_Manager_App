import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/account.dart';

class AccountRepository {
  final DatabaseHelper _databaseHelper;

  AccountRepository(this._databaseHelper);

  Future<List<Account>> getAccounts(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'userId = ? AND isArchived = 0',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }

  Future<Account?> getAccount(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  Future<void> insertAccount(Account account) async {
    final db = await _databaseHelper.database;
    await _databaseHelper.transaction((txn) async {
      await txn.insert(
        'accounts',
        account.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> updateAccount(Account account) async {
    final db = await _databaseHelper.database;
    await _databaseHelper.transaction((txn) async {
      await txn.update(
        'accounts',
        account.toMap(),
        where: 'id = ?',
        whereArgs: [account.id],
      );
    });
  }

  Future<void> deleteAccount(String id) async {
    final db = await _databaseHelper.database;
    await _databaseHelper.transaction((txn) async {
      await txn.delete('accounts', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> archiveAccount(String id) async {
    final db = await _databaseHelper.database;
    await db.update(
      'accounts',
      {'isArchived': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalBalance(String userId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(balance) as total
      FROM accounts
      WHERE userId = ? AND isArchived = 0
    ''',
      [userId],
    );

    return result.first['total'] as double? ?? 0.0;
  }

  Future<List<Account>> getArchivedAccounts(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'userId = ? AND isArchived = 1',
      whereArgs: [userId],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }

  Future<void> restoreAccount(String id) async {
    final db = await _databaseHelper.database;
    await db.update(
      'accounts',
      {'isArchived': 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Account>> searchAccounts(String userId, String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'userId = ? AND isArchived = 0 AND name LIKE ?',
      whereArgs: [userId, '%$query%'],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }

  Future<void> updateAccountBalance(String id, double newBalance) async {
    final db = await _databaseHelper.database;
    await db.update(
      'accounts',
      {'balance': newBalance, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
