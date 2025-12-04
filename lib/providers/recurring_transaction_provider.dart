import 'package:flutter/material.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../services/recurring_transaction_service.dart';
import '../services/transaction_service.dart';
import '../services/connectivity_service.dart';

class RecurringTransactionProvider with ChangeNotifier {
  final RecurringTransactionService _recurringTransactionService =
      RecurringTransactionService();
  final TransactionService _transactionService = TransactionService();
  final ConnectivityService _connectivityService = ConnectivityService();

  List<RecurringTransaction> _recurringTransactions = [];
  bool _isLoading = false;
  String? _error;

  List<RecurringTransaction> get recurringTransactions =>
      _recurringTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRecurringTransactions({
    String? userId,
    RecurringStatus? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recurringTransactions = await _recurringTransactionService
          .getRecurringTransactions(userId: userId, status: status);
    } catch (e) {
      _error = 'فشل في تحميل المعاملات المتكررة: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> addRecurringTransaction(
    RecurringTransaction recurringTransaction,
  ) async {
    try {
      final String id = await _recurringTransactionService
          .addRecurringTransaction(recurringTransaction);

      // إضافة المعاملة المتكررة إلى القائمة
      _recurringTransactions.add(recurringTransaction.copyWith(id: id));
      notifyListeners();

      // مزامنة مع السحابة إذا كان متصلاً
      if (_connectivityService.isConnected) {
        // TODO: إضافة دعم المزامنة مع Firestore
        // await _syncService.queueRecurringTransactionOperation('add', recurringTransaction);
      }

      return id;
    } catch (e) {
      _error = 'فشل في إضافة المعاملة المتكررة: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRecurringTransaction(
    RecurringTransaction recurringTransaction,
  ) async {
    try {
      await _recurringTransactionService.updateRecurringTransaction(
        recurringTransaction,
      );

      // تحديث المعاملة في القائمة
      final index = _recurringTransactions.indexWhere(
        (rt) => rt.id == recurringTransaction.id,
      );
      if (index != -1) {
        _recurringTransactions[index] = recurringTransaction;
        notifyListeners();
      }

      // مزامنة مع السحابة إذا كان متصلاً
      if (_connectivityService.isConnected) {
        // TODO: إضافة دعم المزامنة مع Firestore
        // await _syncService.queueRecurringTransactionOperation('update', recurringTransaction);
      }
    } catch (e) {
      _error = 'فشل في تحديث المعاملة المتكررة: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRecurringTransaction(String id) async {
    try {
      await _recurringTransactionService.deleteRecurringTransaction(id);

      // إزالة المعاملة من القائمة
      _recurringTransactions.removeWhere((rt) => rt.id == id);
      notifyListeners();

      // مزامنة مع السحابة إذا كان متصلاً
      if (_connectivityService.isConnected) {
        // TODO: إضافة دعم المزامنة مع Firestore
        // await _syncService.queueRecurringTransactionOperation('delete', id);
      }
    } catch (e) {
      _error = 'فشل في حذف المعاملة المتكررة: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> executeRecurringTransaction(
    RecurringTransaction recurringTransaction,
  ) async {
    try {
      // إنشاء معاملة جديدة من المعاملة المتكررة
      final now = DateTime.now();
      final transaction = Transaction(
        accountId: recurringTransaction.accountId,
        categoryId: recurringTransaction.categoryId,
        amount: recurringTransaction.amount,
        description: recurringTransaction.description,
        transactionDate: now,
        type: TransactionType.expense, // يمكن تعديل هذا حسب الحاجة
        userId: recurringTransaction.userId,
        isRecurring: true,
        recurringRuleId: recurringTransaction.id,
      );

      // إضافة المعاملة
      await _transactionService.insertTransaction(transaction);

      // تحديث المعاملة المتكررة
      final updatedRecurringTransaction = recurringTransaction.copyWith(
        lastExecuted: now,
        executedCount: recurringTransaction.executedCount + 1,
        updatedAt: now,
      );

      await updateRecurringTransaction(updatedRecurringTransaction);

      // التحقق من انتهاء المعاملة المتكررة
      if (_shouldCompleteRecurringTransaction(updatedRecurringTransaction)) {
        final completedTransaction = updatedRecurringTransaction.copyWith(
          status: RecurringStatus.completed,
          updatedAt: now,
        );
        await updateRecurringTransaction(completedTransaction);
      }
    } catch (e) {
      _error = 'فشل في تنفيذ المعاملة المتكررة: $e';
      notifyListeners();
      rethrow;
    }
  }

  bool _shouldCompleteRecurringTransaction(
    RecurringTransaction recurringTransaction,
  ) {
    // التحقق من انتهاء المعاملة المتكررة
    if (recurringTransaction.maxOccurrences != null) {
      return recurringTransaction.executedCount >=
          recurringTransaction.maxOccurrences!;
    }

    if (recurringTransaction.endDate != null) {
      return DateTime.now().isAfter(recurringTransaction.endDate!);
    }

    return false;
  }

  List<RecurringTransaction> getActiveRecurringTransactions() {
    return _recurringTransactions
        .where((rt) => rt.status == RecurringStatus.active)
        .toList();
  }

  List<RecurringTransaction> getRecurringTransactionsByAccount(
    String accountId,
  ) {
    return _recurringTransactions
        .where((rt) => rt.accountId == accountId)
        .toList();
  }

  List<RecurringTransaction> getRecurringTransactionsByCategory(
    String categoryId,
  ) {
    return _recurringTransactions
        .where((rt) => rt.categoryId == categoryId)
        .toList();
  }

  Future<void> processDueRecurringTransactions() async {
    final now = DateTime.now();
    final activeTransactions = getActiveRecurringTransactions();

    for (final recurringTransaction in activeTransactions) {
      if (_isRecurringTransactionDue(recurringTransaction, now)) {
        await executeRecurringTransaction(recurringTransaction);
      }
    }
  }

  bool _isRecurringTransactionDue(
    RecurringTransaction recurringTransaction,
    DateTime now,
  ) {
    if (recurringTransaction.lastExecuted == null) {
      return now.isAfter(recurringTransaction.startDate);
    }

    final lastExecuted = recurringTransaction.lastExecuted!;
    final nextExecutionDate = _calculateNextExecutionDate(
      lastExecuted,
      recurringTransaction.frequency,
      recurringTransaction.interval,
    );

    return now.isAfter(nextExecutionDate);
  }

  DateTime _calculateNextExecutionDate(
    DateTime lastExecuted,
    RecurringFrequency frequency,
    int interval,
  ) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return lastExecuted.add(Duration(days: interval));
      case RecurringFrequency.weekly:
        return lastExecuted.add(Duration(days: 7 * interval));
      case RecurringFrequency.monthly:
        return DateTime(
          lastExecuted.year,
          lastExecuted.month + interval,
          lastExecuted.day,
        );
      case RecurringFrequency.yearly:
        return DateTime(
          lastExecuted.year + interval,
          lastExecuted.month,
          lastExecuted.day,
        );
      case RecurringFrequency.custom:
        return lastExecuted.add(Duration(days: interval));
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
