// lib/providers/category_provider.dart

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category.dart'; // تأكد من مسار النموذج الصحيح
import '../providers/firestore_provider.dart';
import '../services/category_service.dart';
import '../database/database_helper.dart';

class CategoryProvider with ChangeNotifier {
  final FirestoreProvider _firestoreProvider;
  final CategoryService _categoryService = CategoryService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CategoryProvider({required FirestoreProvider firestoreProvider})
    : _firestoreProvider = firestoreProvider {
    _initializeCategories();
  }

  void _initializeCategories() {
    fetchCategories();
  }

  Future<void> fetchCategories({String? type}) async {
    _setLoading(true);
    _clearError();
    try {
      // First try to get categories from local database
      _categories = await _categoryService.getCategories(type: type);

      if (_categories.isEmpty) {
        // If local database is empty, try to get from Firestore
        try {
          final firestoreCategories =
              await _firestoreProvider.getCategories(type: type).first;
          _categories = firestoreCategories;

          // Save Firestore categories to local database
          for (var category in firestoreCategories) {
            await _categoryService.insertCategory(category);
          }
        } catch (e) {
          print('Failed to get categories from Firestore: ${e.toString()}');
          // If Firestore fails, create default categories
          await _createDefaultCategories();
          _categories = await _categoryService.getCategories(type: type);
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('فشل تحميل الفئات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addCategory(Category category) async {
    _setLoading(true);
    _clearError();
    try {
      // First add to local database
      await _categoryService.insertCategory(category);

      // Then try to sync with Firestore
      try {
        await _firestoreProvider.saveCategory(category);
      } catch (e) {
        print('Failed to save category to Firestore: ${e.toString()}');
        // Continue even if Firestore fails
      }

      await fetchCategories();
    } catch (e) {
      _setError('فشل إضافة الفئة: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCategory(Category category) async {
    _setLoading(true);
    _clearError();
    try {
      // First update local database
      await _categoryService.updateCategory(category);

      // Then try to sync with Firestore
      try {
        await _firestoreProvider.saveCategory(category);
      } catch (e) {
        print('Failed to update category in Firestore: ${e.toString()}');
        // Continue even if Firestore fails
      }

      await fetchCategories();
    } catch (e) {
      _setError('فشل تحديث الفئة: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCategory(int id ) async {
    _setLoading(true);
    _clearError();
    try {
      // First delete from local database
      await _categoryService.deleteCategory(id.toString());

      // Then try to delete from Firestore
      try {
        await _firestoreProvider.deleteCategory(id);
      } catch (e) {
        print('Failed to delete category from Firestore: ${e.toString()}');
        // Continue even if Firestore fails
      }

      await fetchCategories();
    } catch (e) {
      _setError('فشل حذف الفئة: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // يمكنك إضافة دوال أخرى هنا بناءً على ما تحتاجه الواجهة

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// إنشاء فئات افتراضية
  Future<void> _createDefaultCategories() async {
    try {
      // استخدام 'default_user' كمعرف افتراضي
      final userId = 'default_user';
      
      final defaultExpenseCategories = [
        {'name': 'طعام ومشروبات', 'icon': Icons.restaurant},
        {'name': 'مواصلات', 'icon': Icons.directions_car},
        {'name': 'سكن', 'icon': Icons.home},
        {'name': 'فواتير', 'icon': Icons.receipt_long},
        {'name': 'تسوق', 'icon': Icons.shopping_bag},
        {'name': 'صحة', 'icon': Icons.medical_services},
        {'name': 'ترفيه', 'icon': Icons.movie},
        {'name': 'تعليم', 'icon': Icons.school},
        {'name': 'ملابس', 'icon': Icons.checkroom},
        {'name': 'أخرى', 'icon': Icons.category},
      ];

      final defaultIncomeCategories = [
        {'name': 'راتب', 'icon': Icons.work},
        {'name': 'مكافآت', 'icon': Icons.card_giftcard},
        {'name': 'استثمارات', 'icon': Icons.trending_up},
        {'name': 'هدايا', 'icon': Icons.redeem},
        {'name': 'أخرى', 'icon': Icons.attach_money},
      ];

      final db = await _databaseHelper.database;
      await db.transaction((txn) async {
        // إنشاء فئات المصروفات الافتراضية
        for (var category in defaultExpenseCategories) {
          await txn.insert(
            'categories',
            {
              'id': DateTime.now().millisecondsSinceEpoch.toString() +
                  '_${category['name']}',
              'name': category['name'],
              'type': 'expense',
              'icon': (category['icon'] as IconData).codePoint.toString(),
              'colorValue': 0xFF4CAF50,
              'parentId': null,
              'isDefault': 1,
              'userId': userId,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
              'budgetLimit': null,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        // إنشاء فئات الدخل الافتراضية
        for (var category in defaultIncomeCategories) {
          await txn.insert(
            'categories',
            {
              'id': DateTime.now().millisecondsSinceEpoch.toString() +
                  '_${category['name']}',
              'name': category['name'],
              'type': 'income',
              'icon': (category['icon'] as IconData).codePoint.toString(),
              'colorValue': 0xFF4CAF50,
              'parentId': null,
              'isDefault': 1,
              'userId': userId,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
              'budgetLimit': null,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      });
    } catch (e) {
      print('خطأ في إنشاء الفئات الافتراضية: $e');
    }
  }
}
