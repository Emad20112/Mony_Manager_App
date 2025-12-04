import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
// Removed google_fonts dependency: use Cairo font family via TextStyle
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/transaction_summary.dart';
import '../models/chart_data.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _startDate;
  late DateTime _endDate;
  String? _selectedAccountId;
  bool _isLoading = false;

  // Cached data
  Map<String, double>? _expenseCategoryTotals;
  Map<String, double>? _incomeCategoryTotals;
  List<TransactionSummary> _dailyTransactions = [];
  double? _totalIncome;
  double? _totalExpense;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Default to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReportData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _expenseCategoryTotals = null;
      _incomeCategoryTotals = null;
      _dailyTransactions = [];
    });

    try {
      final transactionProvider = context.read<TransactionProvider>();
      final accountProvider = context.read<AccountProvider>();

      // Get account ID (null means all accounts)
      final selectedAccount = accountProvider.selectedAccount;
      _selectedAccountId = selectedAccount?.id;

      // Load transaction data
      await transactionProvider.fetchTransactions(
        accountId: _selectedAccountId,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Calculate category totals for expenses
      _expenseCategoryTotals = await transactionProvider.getCategoryTotals(
        _selectedAccountId,
        _startDate,
        _endDate,
        type: TransactionType.expense,
      );

      // Calculate category totals for income
      _incomeCategoryTotals = await transactionProvider.getCategoryTotals(
        _selectedAccountId,
        _startDate,
        _endDate,
        type: TransactionType.income,
      );

      // Calculate daily transactions for trends
      _dailyTransactions = await transactionProvider.getDailyTransactionSummary(
        _selectedAccountId,
        _startDate,
        _endDate,
      );

      // Calculate totals
      _totalIncome = await transactionProvider.getAccountTransactionsTotal(
        int.tryParse(_selectedAccountId ?? ''),
        _startDate,
        _endDate,
        type: TransactionType.income,
      );

      _totalExpense = await transactionProvider.getAccountTransactionsTotal(
        int.tryParse(_selectedAccountId ?? ''),
        _startDate,
        _endDate,
        type: TransactionType.expense,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء تحميل البيانات',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            TabBar(
              controller: _tabController,
              labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.cairo(),
              tabs: [
                Tab(text: 'ملخص'),
                Tab(text: 'المصروفات'),
                Tab(text: 'الإيرادات'),
              ],
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSummaryTab(),
                          _buildExpensesTab(),
                          _buildIncomeTab(),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'التقارير المالية',
            style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: _selectAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _selectDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${DateFormat.yMMMd('ar').format(_startDate)} - ${DateFormat.yMMMd('ar').format(_endDate)}',
                      style: GoogleFonts.cairo(fontSize: 14),
                    ),
                    const Icon(Icons.calendar_today, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          ElevatedButton(
            onPressed: _loadReportData,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text('تحديث', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    if (_totalIncome == null || _totalExpense == null) {
      return const Center(child: Text('لا توجد بيانات متاحة'));
    }

    final balance = _totalIncome! - _totalExpense!;
    final savingsRate =
        _totalIncome! > 0 ? (balance / _totalIncome! * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Money Overview Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الملخص المالي',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    'مجموع الإيرادات',
                    _totalIncome!,
                    Colors.green,
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'مجموع المصروفات',
                    _totalExpense!,
                    Colors.red,
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'الرصيد',
                    balance,
                    balance >= 0 ? Colors.green : Colors.red,
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'معدل التوفير',
                    savingsRate,
                    savingsRate >= 15 ? Colors.green : Colors.orange,
                    isPercentage: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Income vs Expense Chart
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مقارنة الإيرادات والمصروفات',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildIncomeVsExpenseChart()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Trend Chart
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإتجاهات المالية',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildTrendChart()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    if (_expenseCategoryTotals == null || _expenseCategoryTotals!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'لا توجد مصروفات في الفترة المحددة',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final categoryProvider = Provider.of<CategoryProvider>(context);

    // Sort categories by amount (descending)
    final categoryData =
        _expenseCategoryTotals!.entries.map((entry) {
            final category = categoryProvider.categories.firstWhere(
              (c) => c.id == int.tryParse(entry.key),
              orElse:
                  () => Category(
                    name: 'غير معروف',
                    type: 'expense',
                    userId: 'default_user',
                  ),
            );
            return MapEntry(category, entry.value);
          }).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تقسيم المصروفات حسب الفئة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: _buildExpensePieChart(categoryData),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category List
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل المصروفات حسب الفئة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...categoryData.map(
                    (entry) => _buildCategoryItem(
                      entry.key,
                      entry.value,
                      _totalExpense!,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeTab() {
    if (_incomeCategoryTotals == null || _incomeCategoryTotals!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'لا توجد إيرادات في الفترة المحددة',
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final categoryProvider = Provider.of<CategoryProvider>(context);

    // Sort categories by amount (descending)
    final categoryData =
        _incomeCategoryTotals!.entries.map((entry) {
            final category = categoryProvider.categories.firstWhere(
              (c) => c.id == int.tryParse(entry.key),
              orElse:
                  () => Category(
                    name: 'غير معروف',
                    type: 'income',
                    userId: 'default_user',
                  ),
            );
            return MapEntry(category, entry.value);
          }).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تقسيم الإيرادات حسب الفئة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: _buildIncomePieChart(categoryData),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category List
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل الإيرادات حسب الفئة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...categoryData.map(
                    (entry) => _buildCategoryItem(
                      entry.key,
                      entry.value,
                      _totalIncome!,
                      isIncome: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    double value,
    Color color, {
    bool isPercentage = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.cairo(fontSize: 16)),
          Text(
            isPercentage
                ? '${value.toStringAsFixed(1)}%'
                : NumberFormat.currency(
                  locale: 'ar',
                  symbol: 'ر.س',
                ).format(value),
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeVsExpenseChart() {
    return SfCircularChart(
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: GoogleFonts.cairo(),
      ),
      series: <CircularSeries>[
        DoughnutSeries<ChartData, String>(
          dataSource: [
            ChartData('الإيرادات', _totalIncome!, Colors.green),
            ChartData('المصروفات', _totalExpense!, Colors.red),
          ],
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          pointColorMapper: (ChartData data, _) => data.color,
          dataLabelMapper: (ChartData data, _) => data.x,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: GoogleFonts.cairo(color: Colors.white),
            labelPosition: ChartDataLabelPosition.inside,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart() {
    if (_dailyTransactions.isEmpty) {
      return Center(
        child: Text('لا توجد بيانات كافية', style: GoogleFonts.cairo()),
      );
    }

    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat.MMMd('ar'),
        intervalType: DateTimeIntervalType.days,
      ),
      primaryYAxis: NumericAxis(
        numberFormat: NumberFormat.compact(locale: 'ar'),
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: GoogleFonts.cairo(),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries>[
        LineSeries<TransactionSummary, DateTime>(
          name: 'الإيرادات',
          dataSource: _dailyTransactions,
          xValueMapper: (TransactionSummary data, _) => data.date,
          yValueMapper: (TransactionSummary data, _) => data.incomeAmount,
          color: Colors.green,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
        LineSeries<TransactionSummary, DateTime>(
          name: 'المصروفات',
          dataSource: _dailyTransactions,
          xValueMapper: (TransactionSummary data, _) => data.date,
          yValueMapper: (TransactionSummary data, _) => data.expenseAmount,
          color: Colors.red,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildExpensePieChart(List<MapEntry<Category, double>> categoryData) {
    return PieChart(
      PieChartData(
        sections:
            categoryData.take(5).map((entry) {
              final total = categoryData.fold(
                0.0,
                (sum, entry) => sum + entry.value,
              );
              final percentage = (entry.value / total * 100);

              return PieChartSectionData(
                color: Color(entry.key.colorValue),
                value: entry.value,
                title: '${percentage.toStringAsFixed(1)}%',
                radius: 100,
                titleStyle: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                badgeWidget: _LabelBadge(
                  entry.key.name,
                  size: 16,
                  borderColor: Color(entry.key.colorValue),
                ),
                badgePositionPercentageOffset: 1.0,
              );
            }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        centerSpaceColor: Colors.white,
      ),
      duration: const Duration(milliseconds: 150),
      curve: Curves.linear,
    );
  }

  Widget _buildIncomePieChart(List<MapEntry<Category, double>> categoryData) {
    return PieChart(
      PieChartData(
        sections:
            categoryData.take(5).map((entry) {
              final total = categoryData.fold(
                0.0,
                (sum, entry) => sum + entry.value,
              );
              final percentage = (entry.value / total * 100);

              return PieChartSectionData(
                color: Color(entry.key.colorValue),
                value: entry.value,
                title: '${percentage.toStringAsFixed(1)}%',
                radius: 100,
                titleStyle: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                badgeWidget: _LabelBadge(
                  entry.key.name,
                  size: 16,
                  borderColor: Color(entry.key.colorValue),
                ),
                badgePositionPercentageOffset: 1.0,
              );
            }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        centerSpaceColor: Colors.white,
      ),
      duration: const Duration(milliseconds: 150),
      curve: Curves.linear,
    );
  }

  Widget _buildCategoryItem(
    Category category,
    double amount,
    double total, {
    bool isIncome = false,
  }) {
    final percentage = total > 0 ? (amount / total) * 100 : 0;
    final color = isIncome ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Color(category.colorValue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                NumberFormat.currency(
                  locale: 'ar',
                  symbol: 'ر.س',
                ).format(amount),
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: Color(category.colorValue),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF6B8E23)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReportData();
    }
  }

  Future<void> _selectAccount() async {
    final accountProvider = context.read<AccountProvider>();
    final accounts = accountProvider.accounts;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر الحساب',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...accounts.map(
                        (account) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(
                              account.colorValue,
                            ).withAlpha((0.2 * 255).round()),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Color(account.colorValue),
                            ),
                          ),
                          title: Text(
                            account.name,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            NumberFormat.currency(
                              locale: 'ar',
                              symbol: account.currency,
                            ).format(account.balance),
                            style: GoogleFonts.cairo(),
                          ),
                          onTap: () {
                            accountProvider.setSelectedAccount(account);
                            Navigator.pop(context);
                            _loadReportData();
                          },
                        ),
                      ),
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.all_inclusive, color: Colors.white),
                        ),
                        title: Text(
                          'جميع الحسابات',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          NumberFormat.currency(
                            locale: 'ar',
                            symbol: 'ر.س',
                          ).format(accountProvider.totalBalance),
                          style: GoogleFonts.cairo(),
                        ),
                        onTap: () {
                          accountProvider.setSelectedAccount(null);
                          Navigator.pop(context);
                          _loadReportData();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Badge widget for pie chart
class _LabelBadge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _LabelBadge(this.text, {required this.size, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      padding: const EdgeInsets.all(1),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: size - 4,
            fontWeight: FontWeight.bold,
            color: borderColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
