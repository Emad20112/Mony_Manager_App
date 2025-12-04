import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('ar', ''), // Arabic
    Locale('en', ''), // English
  ];

  // Getters for localized strings
  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get dashboard => _localizedValues[locale.languageCode]!['dashboard']!;
  String get transactions =>
      _localizedValues[locale.languageCode]!['transactions']!;
  String get reports => _localizedValues[locale.languageCode]!['reports']!;
  String get goals => _localizedValues[locale.languageCode]!['goals']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get addTransaction =>
      _localizedValues[locale.languageCode]!['addTransaction']!;
  String get income => _localizedValues[locale.languageCode]!['income']!;
  String get expense => _localizedValues[locale.languageCode]!['expense']!;
  String get transfer => _localizedValues[locale.languageCode]!['transfer']!;
  String get amount => _localizedValues[locale.languageCode]!['amount']!;
  String get description =>
      _localizedValues[locale.languageCode]!['description']!;
  String get category => _localizedValues[locale.languageCode]!['category']!;
  String get account => _localizedValues[locale.languageCode]!['account']!;
  String get date => _localizedValues[locale.languageCode]!['date']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get edit => _localizedValues[locale.languageCode]!['edit']!;
  String get totalIncome =>
      _localizedValues[locale.languageCode]!['totalIncome']!;
  String get totalExpenses =>
      _localizedValues[locale.languageCode]!['totalExpenses']!;
  String get balance => _localizedValues[locale.languageCode]!['balance']!;
  String get recentTransactions =>
      _localizedValues[locale.languageCode]!['recentTransactions']!;
  String get noTransactions =>
      _localizedValues[locale.languageCode]!['noTransactions']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get success => _localizedValues[locale.languageCode]!['success']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get darkMode => _localizedValues[locale.languageCode]!['darkMode']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get currency => _localizedValues[locale.languageCode]!['currency']!;
  String get notifications =>
      _localizedValues[locale.languageCode]!['notifications']!;
  String get backup => _localizedValues[locale.languageCode]!['backup']!;
  String get restore => _localizedValues[locale.languageCode]!['restore']!;
  String get export => _localizedValues[locale.languageCode]!['export']!;
  String get import => _localizedValues[locale.languageCode]!['import']!;
  String get recurringTransactions =>
      _localizedValues[locale.languageCode]!['recurringTransactions']!;
  String get addRecurringTransaction =>
      _localizedValues[locale.languageCode]!['addRecurringTransaction']!;
  String get frequency => _localizedValues[locale.languageCode]!['frequency']!;
  String get daily => _localizedValues[locale.languageCode]!['daily']!;
  String get weekly => _localizedValues[locale.languageCode]!['weekly']!;
  String get monthly => _localizedValues[locale.languageCode]!['monthly']!;
  String get yearly => _localizedValues[locale.languageCode]!['yearly']!;
  String get custom => _localizedValues[locale.languageCode]!['custom']!;
  String get active => _localizedValues[locale.languageCode]!['active']!;
  String get paused => _localizedValues[locale.languageCode]!['paused']!;
  String get completed => _localizedValues[locale.languageCode]!['completed']!;
  String get cancelled => _localizedValues[locale.languageCode]!['cancelled']!;

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'appTitle': 'مدير الأموال',
      'dashboard': 'لوحة التحكم',
      'transactions': 'المعاملات',
      'reports': 'التقارير',
      'goals': 'الأهداف',
      'profile': 'الملف الشخصي',
      'addTransaction': 'إضافة معاملة',
      'income': 'دخل',
      'expense': 'مصروف',
      'transfer': 'تحويل',
      'amount': 'المبلغ',
      'description': 'الوصف',
      'category': 'الفئة',
      'account': 'الحساب',
      'date': 'التاريخ',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'edit': 'تعديل',
      'totalIncome': 'إجمالي الدخل',
      'totalExpenses': 'إجمالي المصروفات',
      'balance': 'الرصيد',
      'recentTransactions': 'المعاملات الأخيرة',
      'noTransactions': 'لا توجد معاملات',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجح',
      'settings': 'الإعدادات',
      'darkMode': 'الوضع الليلي',
      'language': 'اللغة',
      'currency': 'العملة',
      'notifications': 'الإشعارات',
      'backup': 'النسخ الاحتياطي',
      'restore': 'استعادة',
      'export': 'تصدير',
      'import': 'استيراد',
      'recurringTransactions': 'المعاملات المتكررة',
      'addRecurringTransaction': 'إضافة معاملة متكررة',
      'frequency': 'التكرار',
      'daily': 'يومي',
      'weekly': 'أسبوعي',
      'monthly': 'شهري',
      'yearly': 'سنوي',
      'custom': 'مخصص',
      'active': 'نشط',
      'paused': 'متوقف',
      'completed': 'مكتمل',
      'cancelled': 'ملغي',
    },
    'en': {
      'appTitle': 'Money Manager',
      'dashboard': 'Dashboard',
      'transactions': 'Transactions',
      'reports': 'Reports',
      'goals': 'Goals',
      'profile': 'Profile',
      'addTransaction': 'Add Transaction',
      'income': 'Income',
      'expense': 'Expense',
      'transfer': 'Transfer',
      'amount': 'Amount',
      'description': 'Description',
      'category': 'Category',
      'account': 'Account',
      'date': 'Date',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'totalIncome': 'Total Income',
      'totalExpenses': 'Total Expenses',
      'balance': 'Balance',
      'recentTransactions': 'Recent Transactions',
      'noTransactions': 'No transactions',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'settings': 'Settings',
      'darkMode': 'Dark Mode',
      'language': 'Language',
      'currency': 'Currency',
      'notifications': 'Notifications',
      'backup': 'Backup',
      'restore': 'Restore',
      'export': 'Export',
      'import': 'Import',
      'recurringTransactions': 'Recurring Transactions',
      'addRecurringTransaction': 'Add Recurring Transaction',
      'frequency': 'Frequency',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'custom': 'Custom',
      'active': 'Active',
      'paused': 'Paused',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ar', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
