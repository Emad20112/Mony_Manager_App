import 'package:sqflite/sqflite.dart';
import '../models/budget.dart';
import '../database/database_helper.dart';

class BudgetService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // إضافة ميزانية جديدة
  Future<String> insertBudget(Budget budget) async {
    final Database db = await _databaseHelper.database;

    // إنشاء معرف فريد إذا لم يكن موجوداً
    final budgetWithId =
        budget.id == null
            ? budget.copyWith(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
            )
            : budget;

    final id = await db.insert('budgets', budgetWithId.toMap());

    if (id == 0) {
      throw 'فشل في إضافة الميزانية في قاعدة البيانات';
    }

    return budgetWithId.id!;
  }

  // الحصول على جميع الميزانيات
  Future<List<Budget>> getBudgets({String? categoryId, String? period}) async {
    final Database db = await _databaseHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (categoryId != null) {
      whereClause += 'category_id = ?';
      whereArgs.add(categoryId);
    }

    if (period != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'period = ?';
      whereArgs.add(period);
    }

    List<Map<String, dynamic>> maps;
    if (whereClause.isNotEmpty) {
      maps = await db.query(
        'budgets',
        where: whereClause,
        whereArgs: whereArgs,
      );
    } else {
      maps = await db.query('budgets');
    }

    return List.generate(maps.length, (i) {
      return Budget.fromMap(maps[i]);
    });
  }

  // الحصول على ميزانية محددة بواسطة المعرف
  Future<Budget?> getBudget(int id) async {
    final Database db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Budget.fromMap(maps.first);
    }
    return null;
  }

  // تحديث ميزانية
  Future<int> updateBudget(Budget budget) async {
    final Database db = await _databaseHelper.database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  // حذف ميزانية
  Future<int> deleteBudget(String id) async {
    final Database db = await _databaseHelper.database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // الحصول على الميزانيات النشطة لفترة معينة (مثال: الميزانيات الشهرية للشهر الحالي)
  Future<List<Budget>> getActiveBudgetsForPeriod(DateTime date) async {
    final Database db = await _databaseHelper.database;
    final String dateString = date.toIso8601String();

    // يمكنك تعديل هذا الاستعلام ليناسب منطق الفترات المختلفة (أسبوعي، سنوي)
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'period = ? AND start_date <= ? AND end_date >= ?',
      whereArgs: ['Monthly', dateString, dateString], // مثال للميزانيات الشهرية
    );

    return List.generate(maps.length, (i) {
      return Budget.fromMap(maps[i]);
    });
  }
}
