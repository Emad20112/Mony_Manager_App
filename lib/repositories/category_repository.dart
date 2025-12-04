import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/category.dart';

class CategoryRepository {
  final DatabaseHelper _databaseHelper;

  CategoryRepository(this._databaseHelper);

  Future<List<Category>> getCategories(String userId, {String? type}) async {
    final db = await _databaseHelper.database;
    String whereClause = 'userId = ?';
    List<dynamic> whereArgs = [userId];

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<Category?> getCategory(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<void> insertCategory(Category category) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(Category category) async {
    final db = await _databaseHelper.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await _databaseHelper.database;
    await _databaseHelper.transaction((txn) async {
      // حذف الفئة وتحديث الفئات الفرعية
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);

      // تحديث الفئات الفرعية لتصبح فئات رئيسية
      await txn.update(
        'categories',
        {'parentId': null},
        where: 'parentId = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<Category>> getSubcategories(String parentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'parentId = ?',
      whereArgs: [parentId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<List<Category>> searchCategories(String userId, String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'userId = ? AND name LIKE ?',
      whereArgs: [userId, '%$query%'],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<void> updateCategoryBudget(String id, double? budgetLimit) async {
    final db = await _databaseHelper.database;
    await db.update(
      'categories',
      {
        'budgetLimit': budgetLimit,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Category>> getDefaultCategories(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'userId = ? AND isDefault = 1',
      whereArgs: [userId],
      orderBy: 'type ASC, name ASC',
    );

    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<void> createDefaultCategories(String userId) async {
    final defaultExpenseCategories = [
      'طعام ومشروبات',
      'مواصلات',
      'سكن',
      'فواتير',
      'تسوق',
      'صحة',
      'ترفيه',
      'تعليم',
    ];

    final defaultIncomeCategories = [
      'راتب',
      'مكافآت',
      'استثمارات',
      'هدايا',
      'أخرى',
    ];

    final db = await _databaseHelper.database;
    await _databaseHelper.transaction((txn) async {
      // إنشاء فئات المصروفات الافتراضية
      for (var name in defaultExpenseCategories) {
        await txn.insert('categories', {
          'name': name,
          'type': 'expense',
          'icon': null,
          'parent_category_id': null,
          'created_at': DateTime.now().toIso8601String(),
          'isDefault': 1,
          'userId': userId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      // إنشاء فئات الدخل الافتراضية
      for (var name in defaultIncomeCategories) {
        await txn.insert('categories', {
          'name': name,
          'type': 'income',
          'icon': null,
          'parent_category_id': null,
          'created_at': DateTime.now().toIso8601String(),
          'isDefault': 1,
          'userId': userId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }
}
