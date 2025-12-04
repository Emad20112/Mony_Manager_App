import 'package:flutter/material.dart';
import 'package:mony_manager/screens/transactions_screen.dart';
import 'package:mony_manager/screens/add_transaction_screen.dart';
import 'package:mony_manager/screens/transaction_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// استيراد Providers
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
// استيراد النماذج
import '../models/transaction.dart';
import '../models/account.dart'; // قد تحتاجها لعرض بيانات الحسابات في البطاقات
import '../utils/theme_extensions.dart'; // لألوان التصميم

// TODO: قد تحتاج لاستيراد مكتبة لعرض البطاقات المتكدسة بشكل جذاب إذا لزم الأمر
// import 'package:card_swiper/card_swiper.dart'; // مثال لمكتبة Swiper

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // استخدام الألوان من الثيم بدلاً من الألوان الثابتة

  @override
  void initState() {
    super.initState();
    // عند تهيئة الشاشة، اطلب من Providers جلب البيانات الأولية
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // استخدم listen: false لأننا لا نحتاج لإعادة بناء initState
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );

      // جلب الحسابات أولاً
      await accountProvider.fetchAccounts();
      await accountProvider.fetchTotalBalance();

      // عند تهيئة الشاشة، إذا كان هناك حساب محدد بالفعل، قم بجلب المعاملات المرتبطة به
      // وإلا، اختر أول حساب إذا كان متوفراً
      if (accountProvider.selectedAccount != null) {
        await transactionProvider.refreshTransactions(
          accountId: accountProvider.selectedAccount!.id,
        );
      } else if (accountProvider.accounts.isNotEmpty) {
        // إذا لم يكن هناك حساب محدد، اختر أول حساب
        final firstAccount = accountProvider.accounts.first;
        accountProvider.setSelectedAccount(firstAccount);
        await transactionProvider.refreshTransactions(
          accountId: firstAccount.id,
        );
      } else {
        // إذا لم يكن هناك حسابات، جلب جميع المعاملات
        await transactionProvider.refreshTransactions();
      }

      // جلب الفئات
      await categoryProvider.fetchCategories();
    });
  }

  // Helper to format currency
  String _formatCurrency(double amount, {String symbol = 'ريال'}) {
    // Using SAR as default, consider making this dynamic based on account/settings
    final format = NumberFormat.currency(locale: 'ar_YE', symbol: symbol);
    return format.format(amount);
  }

  // Get icon and color based on transaction type
  IconData _getTransactionIcon(Transaction transaction) {
    if (transaction.type == TransactionType.income) {
      return Icons.arrow_upward;
    } else if (transaction.type == TransactionType.expense) {
      return Icons.arrow_downward;
    } else {
      return Icons.swap_horiz; // For transfers
    }
  }

  // Color _getTransactionColor(Transaction transaction) {
  //   if (transaction.type == TransactionType.income) {
  //     return Colors.green;
  //   } else if (transaction.type == TransactionType.expense) {
  //     return Colors.red;
  //   } else {
  //     return Colors.blue; // For transfers
  //   }
  // } // Not used

  // Get icon based on account type
  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'bank':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Widget _buildStatColumn(
    String label,
    double amount,
    String currency,
    IconData icon,
    Color color,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              color: color.withAlpha((0.85 * 255).round()),
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 2 : 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: isSmallScreen ? 12 : 14),
            SizedBox(width: isSmallScreen ? 2 : 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatCurrency(amount, symbol: ''),
                  style: TextStyle(
                    color: color,
                    fontSize: isSmallScreen ? 11 : 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async {
          final accountProvider = Provider.of<AccountProvider>(
            context,
            listen: false,
          );
          final transactionProvider = Provider.of<TransactionProvider>(
            context,
            listen: false,
          );
          final categoryProvider = Provider.of<CategoryProvider>(
            context,
            listen: false,
          );

          await accountProvider.fetchAccounts();
          await accountProvider.fetchTotalBalance();

          if (accountProvider.selectedAccount != null) {
            await transactionProvider.fetchTransactions(
              accountId: accountProvider.selectedAccount!.id,
            );
          } else {
            await transactionProvider.fetchTransactions();
          }

          await categoryProvider.fetchCategories();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(
                  top: 40.0,
                  left: 14.0,
                  right: 14.0,
                  bottom: 14.0,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).appBarTheme.backgroundColor ??
                          Theme.of(context).colorScheme.primary,
                      (Theme.of(context).appBarTheme.backgroundColor ??
                              Theme.of(context).colorScheme.primary)
                          .withOpacity(0.85),
                    ],
                  ),
                ),

                child: Consumer<AccountProvider>(
                  builder: (context, accountProvider, child) {
                    if (accountProvider.isLoading &&
                        accountProvider.accounts.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final selectedAccount = accountProvider.selectedAccount;
                    final accounts = accountProvider.accounts;

                    return Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            selectedAccount != null
                                ? selectedAccount.name
                                : 'بطاقات الخصم',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'معلومات بطاقتك',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.color
                                  ?.withAlpha((0.7 * 255).round()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        if (accounts.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'اختر الحساب',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.color
                                        ?.withAlpha((0.7 * 255).round()),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).cardTheme.color ??
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withAlpha((0.1 * 255).round()),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: PopupMenuButton<Account>(
                                        onSelected: (Account newValue) async {
                                          // Set selected account first
                                          accountProvider.setSelectedAccount(
                                            newValue,
                                          );

                                          // Then fetch transactions for the new account with refresh
                                          final transactionProvider =
                                              Provider.of<TransactionProvider>(
                                                context,
                                                listen: false,
                                              );

                                          // Reset page and refresh transactions
                                          await transactionProvider
                                              .refreshTransactions(
                                                accountId: newValue.id,
                                              );
                                        },
                                        itemBuilder: (BuildContext context) {
                                          return accounts.map((
                                            Account account,
                                          ) {
                                            final bool isSelected =
                                                selectedAccount?.id ==
                                                account.id;
                                            return PopupMenuItem<Account>(
                                              value: account,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          isSelected
                                                              ? Theme.of(
                                                                    context,
                                                                  )
                                                                  .colorScheme
                                                                  .primary
                                                              : Theme.of(
                                                                    context,
                                                                  )
                                                                  .colorScheme
                                                                  .primary
                                                                  .withAlpha(
                                                                    (0.1 * 255)
                                                                        .round(),
                                                                  ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      _getAccountIcon(
                                                        account.type,
                                                      ),
                                                      color:
                                                          isSelected
                                                              ? Colors.white
                                                              : Theme.of(
                                                                    context,
                                                                  )
                                                                  .colorScheme
                                                                  .primary,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          account.name,
                                                          style: TextStyle(
                                                            color:
                                                                isSelected
                                                                    ? Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .primary
                                                                    : Theme.of(
                                                                          context,
                                                                        )
                                                                        .textTheme
                                                                        .titleMedium
                                                                        ?.color,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          _formatCurrency(
                                                            account.balance,
                                                            symbol:
                                                                account
                                                                    .currency,
                                                          ),
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                  context,
                                                                )
                                                                .textTheme
                                                                .titleMedium
                                                                ?.color
                                                                ?.withAlpha(
                                                                  (0.7 * 255)
                                                                      .round(),
                                                                ),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (selectedAccount?.id ==
                                                      account.id)
                                                    Icon(
                                                      Icons.check_circle,
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                      size: 20,
                                                    ),
                                                ],
                                              ),
                                            );
                                          }).toList();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  _getAccountIcon(
                                                    selectedAccount?.type ??
                                                        'default',
                                                  ),
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      selectedAccount?.name ??
                                                          accounts.first.name,
                                                      style: TextStyle(
                                                        color:
                                                            Theme.of(context)
                                                                .textTheme
                                                                .titleMedium
                                                                ?.color,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Text(
                                                      _formatCurrency(
                                                        selectedAccount
                                                                ?.balance ??
                                                            accounts
                                                                .first
                                                                .balance,
                                                        symbol:
                                                            selectedAccount
                                                                ?.currency ??
                                                            accounts
                                                                .first
                                                                .currency,
                                                      ),
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.color
                                                            ?.withOpacity(0.7),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.keyboard_arrow_down,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                size: 24,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Consumer<AccountProvider>(
                  builder: (context, accountProvider, child) {
                    if (accountProvider.isLoading &&
                        accountProvider.selectedAccount == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final selectedAccount = accountProvider.selectedAccount;
                    if (selectedAccount == null) {
                      return Center(
                        child: Text(
                          'الرجاء اختيار حساب لعرض تفاصيله.',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.titleMedium?.color,
                          ),
                        ),
                      );
                    }

                    final screenWidth = MediaQuery.of(context).size.width;
                    final screenHeight = MediaQuery.of(context).size.height;
                    final isSmallScreen = screenWidth < 360;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          constraints: BoxConstraints(
                            minHeight: screenHeight * 0.20,
                            maxHeight: screenHeight * 0.28,
                          ),
                          margin: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.018,
                          ),
                          child: Stack(
                            children: [
                              // Background Card with Gradient
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.05,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.85),
                                    ],
                                    stops: const [0.3, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.2),
                                      blurRadius: screenWidth * 0.03,
                                      offset: Offset(0, screenHeight * 0.0010),
                                    ),
                                  ],
                                ),
                              ),
                              // Card Content
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
                                  vertical: isSmallScreen ? 12.0 : 16.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getAccountIcon(
                                                  selectedAccount.type,
                                                ),
                                                color: Colors.white,
                                                size: isSmallScreen ? 18 : 22,
                                              ),
                                              SizedBox(
                                                width: screenWidth * 0.02,
                                              ),
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    selectedAccount.type ==
                                                            'bank'
                                                        ? 'حساب جاري'
                                                        : selectedAccount.type,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize:
                                                          isSmallScreen
                                                              ? 13
                                                              : 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(
                                            isSmallScreen ? 6.0 : 8.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(
                                              (0.15 * 255).round(),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              screenWidth * 0.02,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.credit_card,
                                            color: Colors.white,
                                            size: isSmallScreen ? 16 : 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: isSmallScreen ? 8.0 : 12.0,
                                    ),
                                    Text(
                                      'الرصيد الحالي',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(
                                          (0.85 * 255).round(),
                                        ),
                                        fontSize: isSmallScreen ? 11 : 13,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 2.0 : 4.0),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _formatCurrency(
                                          selectedAccount.balance,
                                          symbol: selectedAccount.currency,
                                        ),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 20 : 26,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: isSmallScreen ? 8.0 : 12.0,
                                    ),
                                    Consumer<TransactionProvider>(
                                      builder: (
                                        context,
                                        transactionProvider,
                                        _,
                                      ) {
                                        final transactions =
                                            transactionProvider.transactions
                                                .where(
                                                  (t) =>
                                                      t.accountId ==
                                                      selectedAccount.id,
                                                )
                                                .toList();

                                        final totalIncome = transactions
                                            .where(
                                              (t) =>
                                                  t.type ==
                                                  TransactionType.income,
                                            )
                                            .fold(
                                              0.0,
                                              (sum, t) => sum + t.amount,
                                            );

                                        final totalExpense = transactions
                                            .where(
                                              (t) =>
                                                  t.type ==
                                                  TransactionType.expense,
                                            )
                                            .fold(
                                              0.0,
                                              (sum, t) => sum + t.amount,
                                            );

                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: _buildStatColumn(
                                                'الدخل',
                                                totalIncome,
                                                selectedAccount.currency,
                                                Icons.arrow_upward,
                                                Colors.white,
                                                isSmallScreen,
                                              ),
                                            ),
                                            Container(
                                              height: isSmallScreen ? 20 : 24,
                                              width: 1,
                                              color: Colors.white.withAlpha(
                                                (0.2 * 255).round(),
                                              ),
                                            ),
                                            Flexible(
                                              child: _buildStatColumn(
                                                'المصروفات',
                                                totalExpense,
                                                selectedAccount.currency,
                                                Icons.arrow_downward,
                                                Colors.white,
                                                isSmallScreen,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المعاملات',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'أحدث نشاط للحساب',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.color
                                    ?.withAlpha((0.7 * 255).round()),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const TransactionsScreen(),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(
                            'عرض الكل',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Consumer3<
                      TransactionProvider,
                      CategoryProvider,
                      AccountProvider
                    >(
                      builder: (
                        context,
                        transactionProvider,
                        categoryProvider,
                        accountProvider,
                        child,
                      ) {
                        // Show loading only if transactions are loading and we have a selected account
                        if (transactionProvider.isLoading &&
                            accountProvider.selectedAccount != null) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (categoryProvider.isLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final selectedAccount = accountProvider.selectedAccount;
                        if (selectedAccount == null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 48,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.color
                                      ?.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'الرجاء اختيار حساب لعرض معاملاته',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.color
                                        ?.withOpacity(0.7),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Get all transactions for the selected account, sorted by date (newest first)
                        final allTransactions =
                            transactionProvider.transactions
                                .where((t) => t.accountId == selectedAccount.id)
                                .toList();

                        // Sort by date (newest first)
                        allTransactions.sort(
                          (a, b) =>
                              b.transactionDate.compareTo(a.transactionDate),
                        );

                        // Take only the 5 most recent
                        final recentTransactions =
                            allTransactions.take(5).toList();

                        if (recentTransactions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 48,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.color
                                      ?.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد معاملات في هذا الحساب',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.color
                                        ?.withOpacity(0.7),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const AddTransactionScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('إضافة معاملة جديدة'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = recentTransactions[index];
                            final category = categoryProvider.categories
                                .firstWhereOrNull(
                                  (cat) => cat.id == transaction.categoryId,
                                );
                            final bool isExpense =
                                transaction.type == TransactionType.expense;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).cardTheme.color ??
                                    Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                TransactionDetailScreen(
                                                  transaction: transaction,
                                                ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: (isExpense
                                                    ? Theme.of(
                                                      context,
                                                    ).expenseColor
                                                    : Theme.of(
                                                      context,
                                                    ).incomeColor)
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            _getTransactionIcon(transaction),
                                            color:
                                                isExpense
                                                    ? Theme.of(
                                                      context,
                                                    ).expenseColor
                                                    : Theme.of(
                                                      context,
                                                    ).incomeColor,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                category?.name ??
                                                    (isExpense
                                                        ? 'مصروفات'
                                                        : 'إيرادات'),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                transaction.description ?? '',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.color
                                                      ?.withOpacity(0.7),
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${isExpense ? '-' : '+'} ${_formatCurrency(transaction.amount.abs(), symbol: '')}',
                                              style: TextStyle(
                                                color:
                                                    isExpense
                                                        ? Theme.of(
                                                          context,
                                                        ).expenseColor
                                                        : Theme.of(
                                                          context,
                                                        ).incomeColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat(
                                                'dd MMM, hh:mm a',
                                              ).format(
                                                transaction.transactionDate,
                                              ),
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.color
                                                    ?.withOpacity(0.5),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}

// إضافة extension for firstWhereOrNull إذا لم تكن متوفرة تلقائيًا=
