// lib/providers/account_provider.dart

import 'package:flutter/material.dart';
import 'package:mony_manager/providers/list_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart'; // تأكد من مسار النموذج الصحيح
import '../services/account_service.dart'; // تأكد من مسار الخدمة الصحيح

class AccountProvider with ChangeNotifier {
  final AccountService _accountService = AccountService();
  List<Account> _accounts = [];
  double _totalBalance = 0.0;
  bool _isLoading = false;
  String? _errorMessage;
  Account? _selectedAccount;
  String? _selectedAccountId;
  static const String _selectedAccountIdKey = 'selectedAccountId';

  List<Account> get accounts => _accounts;
  double get totalBalance => _totalBalance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Account? get selectedAccount => _selectedAccount;

  AccountProvider() {
    _loadSelectedAccount();
    fetchAccounts();
    fetchTotalBalance();
  }

  Future<void> _loadSelectedAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIdStr = prefs.getString(_selectedAccountIdKey);
      if (savedIdStr != null) {
        _selectedAccountId = savedIdStr;
      }

      if (_selectedAccountId != null && _accounts.isNotEmpty) {
        _selectedAccount = _accounts.firstWhereOrNull(
          (acc) => acc.id == _selectedAccountId,
        );
        notifyListeners();
      }
    } catch (e) {
      _setError('فشل تحميل الحساب المحدد: ${e.toString()}');
    }
  }

  Future<void> _saveSelectedAccount(String? accountId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (accountId != null) {
        await prefs.setString(_selectedAccountIdKey, accountId);
      } else {
        await prefs.remove(_selectedAccountIdKey);
      }
    } catch (e) {
      _setError('فشل حفظ الحساب المحدد: ${e.toString()}');
    }
  }

  void setSelectedAccount(Account? account) async {
    if (_selectedAccount?.id != account?.id) {
      _selectedAccount = account;
      await _saveSelectedAccount(account?.id);
      notifyListeners();
    }
  }

  Future<void> fetchAccounts() async {
    _setLoading(true);
    _clearError();
    try {
      _accounts = await _accountService.getAccounts();

      // إذا لم تكن هناك حسابات، قم بإنشاء بيانات افتراضية
      if (_accounts.isEmpty) {
        await _createDefaultAccounts();
        _accounts = await _accountService.getAccounts();
      }

      // Handle selected account after fetching accounts
      if (_accounts.isNotEmpty) {
        if (_selectedAccount != null) {
          // تحديث المرجع للحساب المحدد بالبيانات الجديدة
          final updatedAccount = _accounts.firstWhereOrNull(
            (acc) => acc.id == _selectedAccount!.id,
          );
          if (updatedAccount != null) {
            _selectedAccount = updatedAccount;
          } else {
            // إذا لم يعد الحساب المحدد موجوداً، اختر الأول
            _selectedAccount = _accounts.first;
            await _saveSelectedAccount(_selectedAccount!.id);
          }
        } else if (_selectedAccountId != null) {
          // محاولة استعادة الحساب المحدد من المعرف المحفوظ
          final savedAccount = _accounts.firstWhereOrNull(
            (acc) => acc.id == _selectedAccountId,
          );
          if (savedAccount != null) {
            _selectedAccount = savedAccount;
          } else {
            _selectedAccount = _accounts.first;
            await _saveSelectedAccount(_selectedAccount!.id);
          }
        } else {
          // Only set first account if no account is selected
          _selectedAccount = _accounts.first;
          await _saveSelectedAccount(_selectedAccount!.id);
        }
      } else {
        // If no accounts exist, clear selection
        _selectedAccount = null;
        await _saveSelectedAccount(null);
      }

      notifyListeners();
    } catch (e) {
      _setError('فشل تحميل الحسابات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// إنشاء حسابات افتراضية
  Future<void> _createDefaultAccounts() async {
    try {
      // استخدام 'default_user' كمعرف افتراضي
      final userId = 'default_user';

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
          balance: 1000,
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
    } catch (e) {
      print('خطأ في إنشاء الحسابات الافتراضية: $e');
    }
  }

  Future<void> fetchTotalBalance() async {
    // يمكن أن تكون جزءًا من fetchAccounts أو دالة منفصلة إذا كانت عملية مكلفة
    // في هذا المثال، نتركها منفصلة كما كانت في الخدمة
    _setLoading(true);
    _clearError();
    try {
      _totalBalance = await _accountService.getTotalBalance();
    } catch (e) {
      _setError('فشل تحميل الرصيد الإجمالي: ${e.toString()}');
    } finally {
      _setLoading(false);
      notifyListeners(); // أبلغ المستمعين عند تحديث الإجمالي أو حدوث خطأ
    }
  }

  Future<void> addAccount(Account account) async {
    try {
      _setLoading(true);
      _clearError();

      // التحقق من عدم وجود حساب بنفس الاسم
      final existingAccount = _accounts.firstWhereOrNull(
        (acc) =>
            acc.name.trim().toLowerCase() == account.name.trim().toLowerCase(),
      );

      if (existingAccount != null) {
        throw 'يوجد حساب بنفس الاسم بالفعل';
      }

      final String id = await _accountService.insertAccount(account);
      if (id.isEmpty) {
        throw 'فشل في إضافة الحساب';
      }

      await fetchAccounts();
      await fetchTotalBalance();

      final newAccount = _accounts.firstWhereOrNull((acc) => acc.id == id);
      if (newAccount != null) {
        setSelectedAccount(newAccount);
      }
    } catch (e) {
      _setError(e.toString());
      rethrow; // إعادة رمي الخطأ ليتم معالجته في الواجهة
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> updateAccount(Account account) async {
    _setLoading(true);
    _clearError();
    try {
      await _accountService.updateAccount(account);
      await fetchAccounts(); // إعادة تحميل القائمة بعد التحديث
      await fetchTotalBalance();
      if (_selectedAccount != null && _selectedAccount!.id == account.id) {
        // ابحث عن النسخة المحدثة من الحساب في القائمة المحدثة
        final updatedAccount = ListExtension(
          _accounts,
        ).firstWhereOrNull((acc) => acc.id == account.id);
        if (updatedAccount != null) {
          setSelectedAccount(updatedAccount);
        }
      } // إعادة تحميل الإجمالي بعد التحديث
    } catch (e) {
      _setError('فشل تحديث الحساب: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> deleteAccount(String id) async {
    _setLoading(true);
    _clearError();
    try {
      if (_selectedAccount != null && _selectedAccount!.id == id) {
        setSelectedAccount(null);
      }
      await _accountService.deleteAccount(id);
      await fetchAccounts(); // إعادة تحميل القائمة بعد الحذف
      await fetchTotalBalance(); // إعادة تحميل الإجمالي بعد الحذف
    } catch (e) {
      _setError('فشل حذف الحساب: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> updateAccountBalance(String accountId, double amount) async {
    _setLoading(true);
    _clearError();
    try {
      await _accountService.updateAccountBalance(accountId, amount);
      await fetchAccounts(); // لإظهار الرصيد المحدث في القائمة
      await fetchTotalBalance();
      if (_selectedAccount != null && _selectedAccount!.id == accountId) {
        final updatedAccount = _accounts.firstWhereOrNull(
          (acc) => acc.id == accountId,
        );
        if (updatedAccount != null) {
          setSelectedAccount(updatedAccount);
        }
      } // لتحديث الرصيد الإجمالي
    } catch (e) {
      _setError('فشل تحديث رصيد الحساب: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // يمكنك إضافة دوال أخرى هنا بناءً على ما تحتاجه الواجهة
}
