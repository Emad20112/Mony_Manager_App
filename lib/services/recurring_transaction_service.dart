import 'package:sqflite/sqflite.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart' as transaction_model;
import '../database/database_helper.dart';
import 'transaction_service.dart';
import 'notification_service.dart';

class RecurringTransactionService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TransactionService _transactionService = TransactionService();
  final NotificationService _notificationService = NotificationService();

  // Add recurring transaction
  Future<String> addRecurringTransaction(
    RecurringTransaction recurringTransaction,
  ) async {
    final db = await _databaseHelper.database;

    final id = await db.insert(
      'recurring_transactions',
      recurringTransaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id.toString();
  }

  // Get all recurring transactions
  Future<List<RecurringTransaction>> getRecurringTransactions({
    String? userId,
    RecurringStatus? status,
  }) async {
    final db = await _databaseHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'userId = ?';
      whereArgs.add(userId);
    }

    if (status != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'status = ?';
      whereArgs.add(status.name);
    }

    List<Map<String, dynamic>> maps;
    if (whereClause.isNotEmpty) {
      maps = await db.query(
        'recurring_transactions',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'createdAt DESC',
      );
    } else {
      maps = await db.query(
        'recurring_transactions',
        orderBy: 'createdAt DESC',
      );
    }

    return maps.map((map) => RecurringTransaction.fromMap(map)).toList();
  }

  // Get recurring transaction by ID
  Future<RecurringTransaction?> getRecurringTransaction(String id) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return RecurringTransaction.fromMap(maps.first);
    }

    return null;
  }

  // Update recurring transaction
  Future<int> updateRecurringTransaction(
    RecurringTransaction recurringTransaction,
  ) async {
    final db = await _databaseHelper.database;

    return await db.update(
      'recurring_transactions',
      recurringTransaction.toMap(),
      where: 'id = ?',
      whereArgs: [recurringTransaction.id],
    );
  }

  // Delete recurring transaction
  Future<int> deleteRecurringTransaction(String id) async {
    final db = await _databaseHelper.database;

    return await db.delete(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Execute recurring transactions that are due
  Future<List<transaction_model.Transaction>>
  executeDueRecurringTransactions() async {
    final recurringTransactions = await getRecurringTransactions(
      status: RecurringStatus.active,
    );

    final executedTransactions = <transaction_model.Transaction>[];

    for (final recurringTransaction in recurringTransactions) {
      if (recurringTransaction.shouldExecuteNow()) {
        try {
          final transaction = await _executeRecurringTransaction(
            recurringTransaction,
          );
          if (transaction != null) {
            executedTransactions.add(transaction);
          }
        } catch (e) {
          print(
            'Error executing recurring transaction ${recurringTransaction.id}: $e',
          );
        }
      }
    }

    return executedTransactions;
  }

  // Execute a single recurring transaction
  Future<transaction_model.Transaction?> _executeRecurringTransaction(
    RecurringTransaction recurringTransaction,
  ) async {
    // Create transaction from recurring transaction
    final transaction = transaction_model.Transaction(
      accountId: recurringTransaction.accountId,
      categoryId: recurringTransaction.categoryId,
      amount: recurringTransaction.amount,
      type:
          transaction_model
              .TransactionType
              .expense, // Default to expense, could be configurable
      description: recurringTransaction.description,
      transactionDate: DateTime.now(),
      isRecurring: true,
      recurringRuleId: recurringTransaction.id,
      userId: recurringTransaction.userId,
    );

    // Add transaction
    final transactionId = await _transactionService.insertTransaction(
      transaction,
    );
    final createdTransaction = transaction.copyWith(id: transactionId);

    // Update recurring transaction
    final updatedRecurring = recurringTransaction.copyWith(
      lastExecuted: DateTime.now(),
      executedCount: recurringTransaction.executedCount + 1,
      updatedAt: DateTime.now(),
    );

    // Check if recurring transaction should be completed
    RecurringTransaction finalRecurring = updatedRecurring;
    if (recurringTransaction.maxOccurrences != null &&
        updatedRecurring.executedCount >=
            recurringTransaction.maxOccurrences!) {
      finalRecurring = updatedRecurring.copyWith(
        status: RecurringStatus.completed,
      );
    }

    await updateRecurringTransaction(finalRecurring);

    // Schedule next reminder if still active
    if (finalRecurring.status == RecurringStatus.active) {
      final nextDate = finalRecurring.getNextExecutionDate();
      if (nextDate != null) {
        await _notificationService.scheduleRecurringReminder(
          transactionDescription: recurringTransaction.description,
          reminderDate: nextDate.subtract(
            const Duration(hours: 1),
          ), // 1 hour before
          frequency: recurringTransaction.getFrequencyDescription(),
        );
      }
    }

    return createdTransaction;
  }

  // Pause recurring transaction
  Future<int> pauseRecurringTransaction(String id) async {
    final recurringTransaction = await getRecurringTransaction(id);
    if (recurringTransaction == null) return 0;

    final updated = recurringTransaction.copyWith(
      status: RecurringStatus.paused,
      updatedAt: DateTime.now(),
    );

    return await updateRecurringTransaction(updated);
  }

  // Resume recurring transaction
  Future<int> resumeRecurringTransaction(String id) async {
    final recurringTransaction = await getRecurringTransaction(id);
    if (recurringTransaction == null) return 0;

    final updated = recurringTransaction.copyWith(
      status: RecurringStatus.active,
      updatedAt: DateTime.now(),
    );

    return await updateRecurringTransaction(updated);
  }

  // Cancel recurring transaction
  Future<int> cancelRecurringTransaction(String id) async {
    final recurringTransaction = await getRecurringTransaction(id);
    if (recurringTransaction == null) return 0;

    final updated = recurringTransaction.copyWith(
      status: RecurringStatus.cancelled,
      updatedAt: DateTime.now(),
    );

    return await updateRecurringTransaction(updated);
  }

  // Get upcoming recurring transactions
  Future<List<RecurringTransaction>> getUpcomingRecurringTransactions({
    int daysAhead = 7,
  }) async {
    final recurringTransactions = await getRecurringTransactions(
      status: RecurringStatus.active,
    );

    final upcoming = <RecurringTransaction>[];
    final cutoffDate = DateTime.now().add(Duration(days: daysAhead));

    for (final recurringTransaction in recurringTransactions) {
      final nextDate = recurringTransaction.getNextExecutionDate();
      if (nextDate != null && nextDate.isBefore(cutoffDate)) {
        upcoming.add(recurringTransaction);
      }
    }

    // Sort by next execution date
    upcoming.sort((a, b) {
      final aNext = a.getNextExecutionDate();
      final bNext = b.getNextExecutionDate();
      if (aNext == null && bNext == null) return 0;
      if (aNext == null) return 1;
      if (bNext == null) return -1;
      return aNext.compareTo(bNext);
    });

    return upcoming;
  }

  // Get recurring transaction statistics
  Future<Map<String, dynamic>> getRecurringTransactionStats() async {
    final recurringTransactions = await getRecurringTransactions();

    int activeCount = 0;
    int pausedCount = 0;
    int completedCount = 0;
    int cancelledCount = 0;
    double totalAmount = 0.0;

    for (final recurringTransaction in recurringTransactions) {
      switch (recurringTransaction.status) {
        case RecurringStatus.active:
          activeCount++;
          break;
        case RecurringStatus.paused:
          pausedCount++;
          break;
        case RecurringStatus.completed:
          completedCount++;
          break;
        case RecurringStatus.cancelled:
          cancelledCount++;
          break;
      }

      if (recurringTransaction.status == RecurringStatus.active) {
        totalAmount += recurringTransaction.amount;
      }
    }

    return {
      'total': recurringTransactions.length,
      'active': activeCount,
      'paused': pausedCount,
      'completed': completedCount,
      'cancelled': cancelledCount,
      'totalAmount': totalAmount,
    };
  }

  // Schedule all recurring transaction reminders
  Future<void> scheduleAllRecurringReminders() async {
    final recurringTransactions = await getRecurringTransactions(
      status: RecurringStatus.active,
    );

    for (final recurringTransaction in recurringTransactions) {
      final nextDate = recurringTransaction.getNextExecutionDate();
      if (nextDate != null) {
        await _notificationService.scheduleRecurringReminder(
          transactionDescription: recurringTransaction.description,
          reminderDate: nextDate.subtract(const Duration(hours: 1)),
          frequency: recurringTransaction.getFrequencyDescription(),
        );
      }
    }
  }
}
