import 'dart:async';
import 'package:flutter/material.dart';
import '../models/recurring_transaction.dart';
import '../services/recurring_transaction_service.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart';

class RecurringTransactionProcessor {
  static final RecurringTransactionProcessor _instance =
      RecurringTransactionProcessor._internal();
  factory RecurringTransactionProcessor() => _instance;
  RecurringTransactionProcessor._internal();

  final RecurringTransactionService _recurringTransactionService =
      RecurringTransactionService();
  final TransactionService _transactionService = TransactionService();
  Timer? _timer;

  // بدء معالج المعاملات المتكررة
  void startProcessing() {
    // تشغيل المعالج كل ساعة
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      _processRecurringTransactions();
    });

    // تشغيل المعالج فوراً
    _processRecurringTransactions();
  }

  // إيقاف معالج المعاملات المتكررة
  void stopProcessing() {
    _timer?.cancel();
    _timer = null;
  }

  // معالجة المعاملات المتكررة المستحقة
  Future<void> _processRecurringTransactions() async {
    try {
      final activeRecurringTransactions = await _recurringTransactionService
          .getRecurringTransactions(status: RecurringStatus.active);

      final now = DateTime.now();
      final dueTransactions = <RecurringTransaction>[];

      for (final recurringTransaction in activeRecurringTransactions) {
        if (_isRecurringTransactionDue(recurringTransaction, now)) {
          dueTransactions.add(recurringTransaction);
        }
      }

      for (final recurringTransaction in dueTransactions) {
        await _executeRecurringTransaction(recurringTransaction);
      }

      if (dueTransactions.isNotEmpty) {
        debugPrint('تم تنفيذ ${dueTransactions.length} معاملة متكررة');
      }
    } catch (e) {
      debugPrint('خطأ في معالجة المعاملات المتكررة: $e');
    }
  }

  // التحقق من استحقاق المعاملة المتكررة
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

  // حساب تاريخ التنفيذ التالي
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

  // تنفيذ المعاملة المتكررة
  Future<void> _executeRecurringTransaction(
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

      await _recurringTransactionService.updateRecurringTransaction(
        updatedRecurringTransaction,
      );

      // التحقق من انتهاء المعاملة المتكررة
      if (_shouldCompleteRecurringTransaction(updatedRecurringTransaction)) {
        final completedTransaction = updatedRecurringTransaction.copyWith(
          status: RecurringStatus.completed,
          updatedAt: now,
        );
        await _recurringTransactionService.updateRecurringTransaction(
          completedTransaction,
        );
      }
    } catch (e) {
      debugPrint('خطأ في تنفيذ المعاملة المتكررة: $e');
    }
  }

  // التحقق من انتهاء المعاملة المتكررة
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

  // معالجة معاملة متكررة محددة
  Future<void> processSpecificRecurringTransaction(
    String recurringTransactionId,
  ) async {
    try {
      final recurringTransaction = await _recurringTransactionService
          .getRecurringTransaction(recurringTransactionId);
      if (recurringTransaction != null &&
          recurringTransaction.status == RecurringStatus.active) {
        await _executeRecurringTransaction(recurringTransaction);
      }
    } catch (e) {
      debugPrint('خطأ في معالجة المعاملة المتكررة المحددة: $e');
    }
  }

  // الحصول على المعاملات المتكررة المستحقة
  Future<List<RecurringTransaction>> getDueRecurringTransactions() async {
    try {
      final activeRecurringTransactions = await _recurringTransactionService
          .getRecurringTransactions(status: RecurringStatus.active);

      final now = DateTime.now();
      final dueTransactions = <RecurringTransaction>[];

      for (final recurringTransaction in activeRecurringTransactions) {
        if (_isRecurringTransactionDue(recurringTransaction, now)) {
          dueTransactions.add(recurringTransaction);
        }
      }

      return dueTransactions;
    } catch (e) {
      debugPrint('خطأ في الحصول على المعاملات المتكررة المستحقة: $e');
      return [];
    }
  }
}
