import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import '../database/database_helper.dart';

class CategoryService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // إضافة فئة جديدة
  Future<String> insertCategory(Category category) async {
    final Database db = await _databaseHelper.database;

    // إنشاء معرف فريد إذا لم يكن موجوداً
    final categoryWithId =
        category.id == null
            ? category.copyWith(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
            )
            : category;

    final id = await db.insert('categories', categoryWithId.toMap());

    if (id == 0) {
      throw 'فشل في إضافة الفئة في قاعدة البيانات';
    }

    return categoryWithId.id!;
  }

  // الحصول على جميع الفئات
  Future<List<Category>> getCategories({String? type}) async {
    final Database db = await _databaseHelper.database;
    List<Map<String, dynamic>> maps;
    if (type != null) {
      maps = await db.query('categories', where: 'type = ?', whereArgs: [type]);
    } else {
      maps = await db.query('categories');
    }
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  // الحصول على فئة محددة بواسطة المعرف
  Future<Category?> getCategory(String id) async {
    final Database db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  // تحديث فئة
  Future<int> updateCategory(Category category) async {
    final Database db = await _databaseHelper.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // حذف فئة (يجب التعامل مع الفئات الفرعية والمعاملات المرتبطة بها بحذر)
  Future<int> deleteCategory(String id) async {
    final Database db = await _databaseHelper.database;
    // TODO: Add logic to handle subcategories and associated transactions before deletion
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
