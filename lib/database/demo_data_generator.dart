import '../models/user.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../repositories/user_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/goal_repository.dart';
import '../models/goal.dart';

class DemoDataGenerator {
  final UserRepository _userRepository;
  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;
  final GoalRepository _goalRepository;

  DemoDataGenerator({
    required UserRepository userRepository,
    required AccountRepository accountRepository,
    required CategoryRepository categoryRepository,
    required TransactionRepository transactionRepository,
    required GoalRepository goalRepository,
  }) : _userRepository = userRepository,
       _accountRepository = accountRepository,
       _categoryRepository = categoryRepository,
       _transactionRepository = transactionRepository,
       _goalRepository = goalRepository;

  /// إنشاء بيانات تجريبية لمستخدم جديد
  Future<void> generateDemoDataForUser(User user) async {
    print('🔄 إنشاء بيانات تجريبية للمستخدم: ${user.name}');

    // سجل المستخدم إن لم يكن موجوداً لاستخدام الـ repository (ويمنع تحذير الحقل غير المستخدم)
    await _userRepository.insertUser(user);

    // 1. إنشاء حسابات افتراضية
    final accounts = await _createDefaultAccounts(user.id);
    print('✅ تم إنشاء ${accounts.length} حسابات افتراضية');

    // 2. إنشاء فئات افتراضية
    final categories = await _createDefaultCategories(user.id);
    print('✅ تم إنشاء ${categories.length} فئات افتراضية');

    // 3. إنشاء معاملات افتراضية
    final transactions = await _createDefaultTransactions(
      user.id,
      accounts,
      categories,
    );
    print('✅ تم إنشاء ${transactions.length} معاملات افتراضية');

    // 4. إنشاء أهداف افتراضية
    final goals = await _createDefaultGoals(user.id);
    print('✅ تم إنشاء ${goals.length} أهداف افتراضية');
  }

  /// إنشاء حسابات افتراضية
  Future<List<Account>> _createDefaultAccounts(String userId) async {
    final accounts = [
      Account(
        name: 'النقد',
        type: 'cash',
        currency: 'SAR',
        balance: 1000.0,
        userId: userId,
      ),
      Account(
        userId: userId,
        name: 'بنك الراجحي',
        type: 'bank',
        currency: 'SAR',
        balance: 5000.0,
      ),
      Account(
        userId: userId,
        name: 'مدخرات',
        type: 'savings',
        currency: 'SAR',
        balance: 10000.0,
      ),
    ];

    for (final account in accounts) {
      await _accountRepository.insertAccount(account);
    }

    return accounts;
  }

  /// إنشاء فئات افتراضية
  Future<List<Category>> _createDefaultCategories(String userId) async {
    // سيتم استخدام الطريقة الموجودة بالفعل في category_repository
    await _categoryRepository.createDefaultCategories(userId);

    // استرجاع الفئات التي تم إنشاؤها
    return await _categoryRepository.getCategories(userId);
  }

  /// إنشاء معاملات افتراضية
  Future<List<Transaction>> _createDefaultTransactions(
    String userId,
    List<Account> accounts,
    List<Category> categories,
  ) async {
    if (accounts.isEmpty || categories.isEmpty) return [];

    // الحصول على فئات المصروفات والإيرادات (مقارنة مرنة بالحروف الصغيرة)
    final expenseCategories =
        categories
            .where((c) => c.type.toLowerCase().contains('expense'))
            .toList();
    final incomeCategories =
        categories
            .where((c) => c.type.toLowerCase().contains('income'))
            .toList();

    if (expenseCategories.isEmpty || incomeCategories.isEmpty) return [];

    // الحساب الرئيسي
    final mainAccount = accounts.first;

    // تواريخ للمعاملات
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<Transaction> transactions = [];

    // إنشاء معاملات الدخل
    for (int i = 0; i < 3; i++) {
      final category = incomeCategories[i % incomeCategories.length];
      final date = DateTime(today.year, today.month, today.day - (i * 7));

      // تأكد من وجود معرف الفئة والحساب
      if (category.id == null || mainAccount.id == null) continue;

      final transaction = Transaction(
        amount: (1000 + (i * 500)).toDouble(),
        type: TransactionType.income,
        categoryId: category.id!,
        accountId: mainAccount.id!,
        transactionDate: date,
        description: 'دخل شهري ${i + 1}',
        userId: 'default_user',
      );

      transactions.add(transaction);
      await _transactionRepository.insertTransaction(transaction);
    }

    // إنشاء معاملات المصروفات
    for (int i = 0; i < 10; i++) {
      final category = expenseCategories[i % expenseCategories.length];
      final date = DateTime(today.year, today.month, today.day - i);
      final amount = 50.0 + (i * 25);

      if (category.id == null || mainAccount.id == null) continue;

      final transaction = Transaction(
        amount: amount,
        type: TransactionType.expense,
        categoryId: category.id!,
        accountId: mainAccount.id!,
        transactionDate: date,
        userId: 'default_user',
        description: 'مصروف ${category.name}',
      );

      transactions.add(transaction);
      await _transactionRepository.insertTransaction(transaction);
    }

    return transactions;
  }

  /// إنشاء أهداف افتراضية
  Future<List<Goal>> _createDefaultGoals(String userId) async {
    final now = DateTime.now();
    final futureDate = DateTime(now.year + 1, now.month, now.day);

    final goals = [
      Goal.create(
        name: 'شراء سيارة',
        category: 'سيارة',
        targetAmount: 50000.0,
        currentAmount: 10000.0,
        targetDate: futureDate,
        note: 'هدف شراء سيارة جديدة',
      ),
      Goal.create(
        name: 'مدخرات الطوارئ',
        category: 'توفير',
        targetAmount: 20000.0,
        currentAmount: 5000.0,
        targetDate: DateTime(now.year, now.month + 6, now.day),
        note: 'احتياطي للطوارئ',
      ),
      Goal.create(
        name: 'سفر',
        category: 'سفر',
        targetAmount: 15000.0,
        currentAmount: 3000.0,
        targetDate: DateTime(now.year, now.month + 3, now.day),
        note: 'رحلة إلى ماليزيا',
      ),
    ];

    final created = <Goal>[];
    for (final goal in goals) {
      final added = await _goalRepository.addGoal(goal);
      created.add(added);
    }

    return created;
  }
}
