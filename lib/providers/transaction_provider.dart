import 'package:flutter/material.dart';
import 'package:mony_manager/providers/list_extensions.dart';
import '../models/transaction.dart';
import '../models/transaction_summary.dart';
import '../services/transaction_service.dart';
import '../services/cache_service.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';
import '../models/category.dart' as app_category;
import '../models/account.dart';
import 'account_provider.dart';
import 'category_provider.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  final SyncService _syncService = SyncService();
  final ConnectivityService _connectivityService = ConnectivityService();
  AccountProvider _accountProvider;
  CategoryProvider _categoryProvider;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMoreData = true;
  int _currentPage = 0;
  static const int _pageSize = 20;

  TransactionProvider({
    required AccountProvider accountProvider,
    required CategoryProvider categoryProvider,
  }) : _accountProvider = accountProvider,
       _categoryProvider = categoryProvider {
    _loadTransactions();
  }

  List<Transaction> get transactions => [..._transactions];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  AccountProvider get accountProvider => _accountProvider;
  CategoryProvider get categoryProvider => _categoryProvider;

  Future<void> _loadTransactions() async {
    await fetchTransactions();
  }

  // Fetch transactions with caching and pagination
  Future<void> fetchTransactions({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool refresh = false,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // إعادة تعيين الصفحة إذا كان refresh=true
      if (refresh) {
        _currentPage = 0;
        _hasMoreData = true;
      }

      // Check cache first (only for first page and if not refreshing)
      if (!refresh && _currentPage == 0) {
        final cacheKey =
            'transactions_${accountId ?? 'all'}_${categoryId ?? 'all'}_${type?.name ?? 'all'}';
        final cachedData = await CacheService.getCachedData<List<dynamic>>(
          cacheKey,
        );

        if (cachedData != null) {
          _transactions =
              cachedData.map((data) => Transaction.fromMap(data)).toList();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Fetch from database
      final newTransactions = await _transactionService.getTransactions(
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        startDate: startDate,
        endDate: endDate,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        userId: 'default_user', // إضافة userId
      );

      if (refresh || _currentPage == 0) {
        _transactions = newTransactions;
      } else {
        _transactions.addAll(newTransactions);
      }

      _hasMoreData = newTransactions.length == _pageSize;
      _currentPage++;

      // Cache the first page
      if (_currentPage == 1) {
        final cacheKey =
            'transactions_${accountId ?? 'all'}_${categoryId ?? 'all'}_${type?.name ?? 'all'}';
        await CacheService.cacheData(
          cacheKey,
          _transactions.map((t) => t.toMap()).toList(),
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more transactions (pagination)
  Future<void> loadMoreTransactions({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_hasMoreData || _isLoading) return;

    await fetchTransactions(
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Refresh transactions (clear cache and reload)
  Future<void> refreshTransactions({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _currentPage = 0;
    _hasMoreData = true;
    _transactions.clear();

    // Clear cache
    final cacheKey =
        'transactions_${accountId ?? 'all'}_${categoryId ?? 'all'}_${type?.name ?? 'all'}';
    await CacheService.clearCache(cacheKey);

    await fetchTransactions(
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      startDate: startDate,
      endDate: endDate,
      refresh: true,
    );
  }

  double getTotalIncome() {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenses() {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  void _onAccountChanged() {
    if (_accountProvider.selectedAccount != null) {
      fetchTransactions(accountId: _accountProvider.selectedAccount!.id);
    }
  }

  @override
  void dispose() {
    _accountProvider.removeListener(_onAccountChanged);
    super.dispose();
  }

  TransactionProvider update(
    AccountProvider accountProvider,
    CategoryProvider categoryProvider,
  ) {
    _accountProvider = accountProvider;
    _categoryProvider = categoryProvider;
    return this;
  }

  // Public wrapper used by screens: load transactions from DB with optional filters
  Future<void> loadTransactionsFromDB(
    String? userId, {
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // delegate to service
    try {
      _transactions = await _transactionService.getTransactions(
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
      );
      notifyListeners();
    } catch (e) {
      _setError('فشل تحميل المعاملات: ${e.toString()}');
    }
  }

  Future<Map<String, double>> getCategoryTotals(
    String? accountId,
    DateTime startDate,
    DateTime endDate, {
    TransactionType? type,
  }) async {
    // Delegate to repository via service not available, so compute locally
    final Map<String, double> totals = {};
    for (var t in _transactions) {
      if (accountId != null && t.accountId != accountId) continue;
      if (t.transactionDate.isBefore(startDate) ||
          t.transactionDate.isAfter(endDate))
        continue;
      if (type != null && t.type != type) continue;
      totals[t.categoryId] = (totals[t.categoryId] ?? 0.0) + t.amount;
    }
    return totals;
  }

  Future<List<TransactionSummary>> getDailyTransactionSummary(
    String? accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final Map<String, TransactionSummary> map = {};
    DateTime day = DateTime(startDate.year, startDate.month, startDate.day);
    while (!day.isAfter(endDate)) {
      map[day.toIso8601String()] = TransactionSummary(
        date: day,
        incomeAmount: 0.0,
        expenseAmount: 0.0,
      );
      day = day.add(const Duration(days: 1));
    }

    for (var t in _transactions) {
      if (accountId != null && t.accountId != accountId) continue;
      if (t.transactionDate.isBefore(startDate) ||
          t.transactionDate.isAfter(endDate))
        continue;
      final key =
          DateTime(
            t.transactionDate.year,
            t.transactionDate.month,
            t.transactionDate.day,
          ).toIso8601String();
      final existing = map[key];
      if (existing != null) {
        if (t.type == TransactionType.income) {
          map[key] = TransactionSummary(
            date: existing.date,
            incomeAmount: existing.incomeAmount + t.amount,
            expenseAmount: existing.expenseAmount,
          );
        } else {
          map[key] = TransactionSummary(
            date: existing.date,
            incomeAmount: existing.incomeAmount,
            expenseAmount: existing.expenseAmount + t.amount,
          );
        }
      }
    }

    return map.values.toList();
  }

  Future<double> getAccountTransactionsTotal(
    int? accountId,
    DateTime startDate,
    DateTime endDate, {
    TransactionType? type,
  }) async {
    double total = 0.0;
    for (var t in _transactions) {
      if (accountId != null && t.accountId != accountId) continue;
      if (t.transactionDate.isBefore(startDate) ||
          t.transactionDate.isAfter(endDate))
        continue;
      if (type != null && t.type != type) continue;
      total += t.amount * (t.type == TransactionType.expense ? 1 : 1);
    }
    return total;
  }

  Future<void> addTransaction(
    Transaction transaction,
    BuildContext context,
  ) async {
    _setLoading(true);
    _clearError();
    try {
      // Debug logging
      print('TransactionProvider: Adding transaction:');
      print('AccountId: ${transaction.accountId}');
      print('CategoryId: ${transaction.categoryId}');
      print('Amount: ${transaction.amount}');
      print('Type: ${transaction.type}');

      // Transaction model guarantees non-null accountId and categoryId

      print('TransactionProvider: Calling insertTransaction');
      final String transactionId = await _transactionService.insertTransaction(
        transaction,
      );

      print(
        'TransactionProvider: Transaction inserted with ID: $transactionId',
      );
      if (transactionId.isEmpty) {
        throw Exception('فشل في إضافة المعاملة: لم يتم إنشاء معرف للمعاملة');
      }

      // If online, sync to cloud; if offline, queue for later sync
      if (_connectivityService.isConnected) {
        try {
          await _syncService.queueTransactionOperation('add', transaction);
          await _syncService.syncPendingOperations();
        } catch (e) {
          print('Failed to sync transaction: $e');
          // Queue for later sync
          await _syncService.queueTransactionOperation('add', transaction);
        }
      } else {
        // Queue for later sync when online
        await _syncService.queueTransactionOperation('add', transaction);
      }

      // Create the new transaction object with the returned ID
      final createdTransaction = transaction.copyWith(id: transactionId);

      // Optimistically update the local list
      _transactions.insert(0, createdTransaction);
      notifyListeners();

      // Update accounts to refresh balances (this is usually fast)
      print('TransactionProvider: Fetching accounts');
      await _accountProvider.fetchAccounts();

      print('TransactionProvider: Fetching total balance');
      await _accountProvider.fetchTotalBalance();

      _clearError();
    } catch (e) {
      print('TransactionProvider: Error adding transaction: $e');
      _setError('فشل إضافة المعاملة: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

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
  }

  Map<String, double> groupExpensesByCategory(
    List<app_category.Category> categories,
  ) {
    final Map<String, double> data = {};
    final expenseTransactions =
        _transactions.where((t) => t.type == TransactionType.expense).toList();

    for (var transaction in expenseTransactions) {
      final category = categories.firstWhereOrNull(
        (cat) => cat.id == transaction.categoryId,
      );
      final categoryName = category?.name ?? 'فئة غير معروفة';
      data[categoryName] = (data[categoryName] ?? 0.0) + transaction.amount;
    }
    return data;
  }

  Map<String, double> groupIncomeByCategory(
    List<app_category.Category> categories,
  ) {
    final Map<String, double> data = {};
    final incomeTransactions =
        _transactions.where((t) => t.type == TransactionType.income).toList();

    for (var transaction in incomeTransactions) {
      final category = categories.firstWhereOrNull(
        (cat) => cat.id == transaction.categoryId,
      );
      final categoryName = category?.name ?? 'فئة غير معروفة';
      data[categoryName] = (data[categoryName] ?? 0.0) + transaction.amount;
    }
    return data;
  }

  Map<String, double> groupTransactionsByAccount(List<Account> accounts) {
    final Map<String, double> data = {};

    for (var transaction in _transactions) {
      final account = accounts.firstWhereOrNull(
        (acc) => acc.id == transaction.accountId,
      );
      final accountName = account?.name ?? 'حساب غير معروف';
      final amount =
          transaction.type == TransactionType.expense
              ? -transaction.amount
              : transaction.amount;
      data[accountName] = (data[accountName] ?? 0.0) + amount;
    }
    return data;
  }
}
