// lib/providers/budget_provider.dart

import 'package:flutter/material.dart';
import '../models/budget.dart'; // تأكد من مسار النموذج الصحيح
import '../services/budget_service.dart'; // تأكد من مسار الخدمة الصحيح

class BudgetProvider with ChangeNotifier {
  final BudgetService _budgetService = BudgetService();
  List<Budget> _budgets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  BudgetProvider() {
    // يمكنك اختيار تحميل جميع الميزانيات عند التهيئة أو عند الحاجة
    fetchBudgets();
  }

  Future<void> fetchBudgets({String? categoryId, String? period}) async {
    _setLoading(true);
    _clearError();
    try {
      _budgets = await _budgetService.getBudgets(
        categoryId: categoryId,
        period: period,
      );
    } catch (e) {
      _setError('فشل تحميل الميزانيات: ${e.toString()}');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchActiveBudgetsForPeriod(DateTime date) async {
    _setLoading(true);
    _clearError();
    try {
      _budgets = await _budgetService.getActiveBudgetsForPeriod(date);
    } catch (e) {
      _setError('فشل تحميل الميزانيات النشطة: ${e.toString()}');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> addBudget(Budget budget) async {
    _setLoading(true);
    _clearError();
    try {
      final String id = await _budgetService.insertBudget(budget);
      if (id.isEmpty) {
        throw 'فشل في إضافة الميزانية';
      }
      await fetchBudgets(); // إعادة تحميل القائمة بعد الإضافة
    } catch (e) {
      _setError('فشل إضافة الميزانية: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> updateBudget(Budget budget) async {
    _setLoading(true);
    _clearError();
    try {
      await _budgetService.updateBudget(budget);
      await fetchBudgets(); // إعادة تحميل القائمة بعد التحديث
    } catch (e) {
      _setError('فشل تحديث الميزانية: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> deleteBudget(String id) async {
    _setLoading(true);
    _clearError();
    try {
      await _budgetService.deleteBudget(id);
      await fetchBudgets(); // إعادة تحميل القائمة بعد الحذف
    } catch (e) {
      _setError('فشل حذف الميزانية: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
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
}
