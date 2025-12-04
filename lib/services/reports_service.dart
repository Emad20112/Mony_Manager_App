// import 'package:flutter/material.dart'; // Not used
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../services/transaction_service.dart';
import '../services/account_service.dart';
import '../services/category_service.dart';

class ReportsService {
  final TransactionService _transactionService = TransactionService();
  final AccountService _accountService = AccountService();
  final CategoryService _categoryService = CategoryService();

  // Get monthly spending report
  Future<Map<String, dynamic>> getMonthlySpendingReport({
    required DateTime month,
    String? userId,
  }) async {
    try {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final transactions = await _transactionService.getTransactions(
        accountId: null,
        categoryId: null,
        startDate: startDate,
        endDate: endDate,
        type: TransactionType.expense,
        limit: null,
        offset: null,
      );

      final categories = await _categoryService.getCategories();
      final accounts = await _accountService.getAccounts();

      // Calculate totals by category
      final categoryTotals = <String, double>{};
      final accountTotals = <String, double>{};
      double totalSpent = 0.0;

      for (final transaction in transactions) {
        totalSpent += transaction.amount;

        // Category totals
        categoryTotals[transaction.categoryId] =
            (categoryTotals[transaction.categoryId] ?? 0.0) +
            transaction.amount;

        // Account totals
        accountTotals[transaction.accountId] =
            (accountTotals[transaction.accountId] ?? 0.0) + transaction.amount;
      }

      // Get category names
      final categoryBreakdown = <Map<String, dynamic>>[];
      for (final entry in categoryTotals.entries) {
        final category = categories.firstWhere(
          (cat) => cat.id == entry.key,
          orElse:
              () => Category(
                id: entry.key,
                name: 'Unknown',
                type: 'expense',
                userId: 'default_user',
              ),
        );
        categoryBreakdown.add({
          'categoryId': entry.key,
          'categoryName': category.name,
          'amount': entry.value,
          'percentage': totalSpent > 0 ? (entry.value / totalSpent * 100) : 0.0,
        });
      }

      // Get account names
      final accountBreakdown = <Map<String, dynamic>>[];
      for (final entry in accountTotals.entries) {
        final account = accounts.firstWhere(
          (acc) => acc.id == entry.key,
          orElse:
              () => Account(
                userId: userId,
                id: entry.key,
                name: 'Unknown',
                balance: 0.0,
                type: 'cash',
              ),
        );
        accountBreakdown.add({
          'accountId': entry.key,
          'accountName': account.name,
          'amount': entry.value,
          'percentage': totalSpent > 0 ? (entry.value / totalSpent * 100) : 0.0,
        });
      }

      // Sort by amount (descending)
      categoryBreakdown.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
      );
      accountBreakdown.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
      );

      return {
        'month': month,
        'totalSpent': totalSpent,
        'transactionCount': transactions.length,
        'categoryBreakdown': categoryBreakdown,
        'accountBreakdown': accountBreakdown,
        'averageDailySpending':
            totalSpent / DateTime(month.year, month.month + 1, 0).day,
        'topCategory':
            categoryBreakdown.isNotEmpty ? categoryBreakdown.first : null,
        'topAccount':
            accountBreakdown.isNotEmpty ? accountBreakdown.first : null,
      };
    } catch (e) {
      throw Exception('Failed to generate monthly spending report: $e');
    }
  }

  // Get yearly spending report
  Future<Map<String, dynamic>> getYearlySpendingReport({
    required int year,
    String? userId,
  }) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31, 23, 59, 59);

      final transactions = await _transactionService.getTransactions(
        accountId: null,
        categoryId: null,
        startDate: startDate,
        endDate: endDate,
        type: TransactionType.expense,
        limit: null,
        offset: null,
      );

      // Calculate monthly breakdown
      final monthlyBreakdown = <Map<String, dynamic>>[];
      for (int month = 1; month <= 12; month++) {
        final monthStart = DateTime(year, month, 1);
        final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);

        final monthTransactions = transactions.where(
          (txn) =>
              txn.transactionDate.isAfter(
                monthStart.subtract(const Duration(days: 1)),
              ) &&
              txn.transactionDate.isBefore(
                monthEnd.add(const Duration(days: 1)),
              ),
        );

        final monthTotal = monthTransactions.fold(
          0.0,
          (sum, txn) => sum + txn.amount,
        );

        monthlyBreakdown.add({
          'month': month,
          'monthName': _getMonthName(month),
          'amount': monthTotal,
          'transactionCount': monthTransactions.length,
        });
      }

      final totalSpent = transactions.fold(0.0, (sum, txn) => sum + txn.amount);
      final averageMonthlySpending = totalSpent / 12;

      return {
        'year': year,
        'totalSpent': totalSpent,
        'transactionCount': transactions.length,
        'monthlyBreakdown': monthlyBreakdown,
        'averageMonthlySpending': averageMonthlySpending,
        'highestSpendingMonth':
            monthlyBreakdown.isNotEmpty
                ? monthlyBreakdown.reduce(
                  (a, b) => a['amount'] > b['amount'] ? a : b,
                )
                : null,
        'lowestSpendingMonth':
            monthlyBreakdown.isNotEmpty
                ? monthlyBreakdown.reduce(
                  (a, b) => a['amount'] < b['amount'] ? a : b,
                )
                : null,
      };
    } catch (e) {
      throw Exception('Failed to generate yearly spending report: $e');
    }
  }

  // Get category spending trends
  Future<Map<String, dynamic>> getCategorySpendingTrends({
    required String categoryId,
    required int months,
    String? userId,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month - months + 1, 1);

      final transactions = await _transactionService.getTransactions(
        accountId: null,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
        type: TransactionType.expense,
        limit: null,
        offset: null,
      );

      final category = await _categoryService.getCategory(categoryId);

      // Calculate monthly trends
      final monthlyTrends = <Map<String, dynamic>>[];
      for (int i = 0; i < months; i++) {
        final month = DateTime(endDate.year, endDate.month - i, 1);
        final monthStart = DateTime(month.year, month.month, 1);
        final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

        final monthTransactions = transactions.where(
          (txn) =>
              txn.transactionDate.isAfter(
                monthStart.subtract(const Duration(days: 1)),
              ) &&
              txn.transactionDate.isBefore(
                monthEnd.add(const Duration(days: 1)),
              ),
        );

        final monthTotal = monthTransactions.fold(
          0.0,
          (sum, txn) => sum + txn.amount,
        );

        monthlyTrends.add({
          'month': month,
          'monthName': _getMonthName(month.month),
          'amount': monthTotal,
          'transactionCount': monthTransactions.length,
        });
      }

      // Reverse to get chronological order
      monthlyTrends.reversed.toList();

      final totalSpent = transactions.fold(0.0, (sum, txn) => sum + txn.amount);
      final averageMonthlySpending = totalSpent / months;

      return {
        'categoryId': categoryId,
        'categoryName': category?.name ?? 'Unknown',
        'period': months,
        'totalSpent': totalSpent,
        'transactionCount': transactions.length,
        'monthlyTrends': monthlyTrends,
        'averageMonthlySpending': averageMonthlySpending,
        'trend': _calculateTrend(monthlyTrends),
      };
    } catch (e) {
      throw Exception('Failed to generate category spending trends: $e');
    }
  }

  // Get income vs expenses report
  Future<Map<String, dynamic>> getIncomeVsExpensesReport({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    try {
      final incomeTransactions = await _transactionService.getTransactions(
        accountId: null,
        categoryId: null,
        startDate: startDate,
        endDate: endDate,
        type: TransactionType.income,
        limit: null,
        offset: null,
      );

      final expenseTransactions = await _transactionService.getTransactions(
        accountId: null,
        categoryId: null,
        startDate: startDate,
        endDate: endDate,
        type: TransactionType.expense,
        limit: null,
        offset: null,
      );

      final totalIncome = incomeTransactions.fold(
        0.0,
        (sum, txn) => sum + txn.amount,
      );
      final totalExpenses = expenseTransactions.fold(
        0.0,
        (sum, txn) => sum + txn.amount,
      );
      final netIncome = totalIncome - totalExpenses;

      return {
        'period': {'startDate': startDate, 'endDate': endDate},
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netIncome': netIncome,
        'incomeCount': incomeTransactions.length,
        'expenseCount': expenseTransactions.length,
        'savingsRate': totalIncome > 0 ? (netIncome / totalIncome * 100) : 0.0,
        'expenseRatio':
            totalIncome > 0 ? (totalExpenses / totalIncome * 100) : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to generate income vs expenses report: $e');
    }
  }

  // Get spending patterns report
  Future<Map<String, dynamic>> getSpendingPatternsReport({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    try {
      final transactions = await _transactionService.getTransactions(
        accountId: null,
        categoryId: null,
        startDate: startDate,
        endDate: endDate,
        type: TransactionType.expense,
        limit: null,
        offset: null,
      );

      // Analyze spending by day of week
      final dayOfWeekSpending = <int, double>{};
      final dayOfWeekCount = <int, int>{};

      // Analyze spending by hour of day
      final hourOfDaySpending = <int, double>{};
      final hourOfDayCount = <int, int>{};

      for (final transaction in transactions) {
        final dayOfWeek = transaction.transactionDate.weekday;
        final hourOfDay = transaction.transactionDate.hour;

        dayOfWeekSpending[dayOfWeek] =
            (dayOfWeekSpending[dayOfWeek] ?? 0.0) + transaction.amount;
        dayOfWeekCount[dayOfWeek] = (dayOfWeekCount[dayOfWeek] ?? 0) + 1;

        hourOfDaySpending[hourOfDay] =
            (hourOfDaySpending[hourOfDay] ?? 0.0) + transaction.amount;
        hourOfDayCount[hourOfDay] = (hourOfDayCount[hourOfDay] ?? 0) + 1;
      }

      // Convert to lists for easier processing
      final dayOfWeekBreakdown = <Map<String, dynamic>>[];
      for (int day = 1; day <= 7; day++) {
        dayOfWeekBreakdown.add({
          'day': day,
          'dayName': _getDayName(day),
          'amount': dayOfWeekSpending[day] ?? 0.0,
          'count': dayOfWeekCount[day] ?? 0,
          'average':
              dayOfWeekCount[day] != null && dayOfWeekCount[day]! > 0
                  ? dayOfWeekSpending[day]! / dayOfWeekCount[day]!
                  : 0.0,
        });
      }

      final hourOfDayBreakdown = <Map<String, dynamic>>[];
      for (int hour = 0; hour < 24; hour++) {
        hourOfDayBreakdown.add({
          'hour': hour,
          'amount': hourOfDaySpending[hour] ?? 0.0,
          'count': hourOfDayCount[hour] ?? 0,
          'average':
              hourOfDayCount[hour] != null && hourOfDayCount[hour]! > 0
                  ? hourOfDaySpending[hour]! / hourOfDayCount[hour]!
                  : 0.0,
        });
      }

      return {
        'period': {'startDate': startDate, 'endDate': endDate},
        'totalTransactions': transactions.length,
        'dayOfWeekBreakdown': dayOfWeekBreakdown,
        'hourOfDayBreakdown': hourOfDayBreakdown,
        'busiestDay':
            dayOfWeekBreakdown.isNotEmpty
                ? dayOfWeekBreakdown.reduce(
                  (a, b) => a['amount'] > b['amount'] ? a : b,
                )
                : null,
        'busiestHour':
            hourOfDayBreakdown.isNotEmpty
                ? hourOfDayBreakdown.reduce(
                  (a, b) => a['amount'] > b['amount'] ? a : b,
                )
                : null,
      };
    } catch (e) {
      throw Exception('Failed to generate spending patterns report: $e');
    }
  }

  // Helper methods
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _getDayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[day - 1];
  }

  String _calculateTrend(List<Map<String, dynamic>> monthlyTrends) {
    if (monthlyTrends.length < 2) return 'stable';

    final firstAmount = monthlyTrends.first['amount'] as double;
    final lastAmount = monthlyTrends.last['amount'] as double;

    final change = lastAmount - firstAmount;
    final changePercent = firstAmount > 0 ? (change / firstAmount * 100) : 0;

    if (changePercent > 10) return 'increasing';
    if (changePercent < -10) return 'decreasing';
    return 'stable';
  }
}
