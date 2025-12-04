import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/transaction.dart' as app_models;
import '../models/account.dart';
import '../models/category.dart';

class FirestoreProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // تهيئة بيانات المستخدم
  Future<void> initializeUserData(String userId) async {
    _setLoading(true);
    try {
      await _firestoreService.initializeUserData(userId);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // الحسابات
  Stream<List<Account>> get accounts => _firestoreService.getAccounts();

  Future<void> saveAccount(Account account) async {
    _setLoading(true);
    try {
      await _firestoreService.saveAccount(account);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount(int accountId) async {
    _setLoading(true);
    try {
      await _firestoreService.deleteAccount(accountId.toString());
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // الفئات
  Stream<List<Category>> getCategories({String? type}) =>
      _firestoreService.getCategories(type: type);

  Future<void> saveCategory(Category category) async {
    _setLoading(true);
    try {
      await _firestoreService.saveCategory(category);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    _setLoading(true);
    try {
      await _firestoreService.deleteCategory(categoryId.toString());
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // المعاملات
  Stream<List<app_models.Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _firestoreService.getTransactions(startDate: startDate, endDate: endDate);

  Future<void> saveTransaction(app_models.Transaction transaction) async {
    _setLoading(true);
    try {
      await _firestoreService.saveTransaction(transaction);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTransaction(int transactionId) async {
    _setLoading(true);
    try {
      await _firestoreService.deleteTransaction(transactionId.toString());
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // المساعدين
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
