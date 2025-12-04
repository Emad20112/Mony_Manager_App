import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../services/category_service.dart';
import '../database/database_helper.dart';

/// خدمة لإنشاء البيانات الافتراضية تلقائياً
class DefaultDataService {
  final AccountService _accountService = AccountService();
  final CategoryService _categoryService = CategoryService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// إنشاء بيانات افتراضية إذا لم تكن موجودة
  Future<void> initializeDefaultData(String userId) async {
    try {
      // التحقق من وجود حسابات
      final accounts = await _accountService.getAccounts();
      if (accounts.isEmpty) {
        await _createDefaultAccounts(userId);
      }

      // التحقق من وجود فئات
      final categories = await _categoryService.getCategories();
      if (categories.isEmpty) {
        await _createDefaultCategories(userId);
      }
    } catch (e) {
      print('خطأ في إنشاء البيانات الافتراضية: $e');
    }
  }

  /// إنشاء حسابات افتراضية
  Future<void> _createDefaultAccounts(String userId) async {
    final defaultAccounts = [
      Account(
        name: 'النقد',
        type: 'cash',
        currency: 'SAR',
        balance: 0.0,
        userId: userId,
        colorValue: 0xFF4CAF50,
        icon: Icons.money.codePoint.toString(),
      ),
      Account(
        name: 'حساب بنكي',
        type: 'bank',
        currency: 'SAR',
        balance: 0.0,
        userId: userId,
        colorValue: 0xFF2196F3,
        icon: Icons.account_balance.codePoint.toString(),
      ),
    ];

    for (final account in defaultAccounts) {
      try {
        await _accountService.insertAccount(account);
      } catch (e) {
        print('خطأ في إنشاء الحساب ${account.name}: $e');
      }
    }
  }

  /// إنشاء فئات افتراضية مع أيقونات
  Future<void> _createDefaultCategories(String userId) async {
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
        await txn.insert('categories', {
          'id':
              DateTime.now().millisecondsSinceEpoch.toString() +
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
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      // إنشاء فئات الدخل الافتراضية
      for (var category in defaultIncomeCategories) {
        await txn.insert('categories', {
          'id':
              DateTime.now().millisecondsSinceEpoch.toString() +
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
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }
}
