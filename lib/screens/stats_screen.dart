// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:mony_manager/screens/add_category_screen.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/transaction.dart';
import '../widgets/analysis_chart.dart';
import '../widgets/financial_summary.dart';
import '../utils/number_utils.dart';
import '../providers/wishes_provider.dart';
import '../widgets/wish_item.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final String _selectedPeriod = 'شهري';

  @override
  void initState() {
    super.initState();
    // جلب البيانات عند تهيئة الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).fetchTransactions();
    });
  }

  // Helper to format currency
  String _formatCurrency(double amount) {
    final formattedNumber = _formatLargeNumber(amount);
    return '$formattedNumber ريال';
  }

  // تحسين تنسيق الأرقام الكبيرة
  String _formatLargeNumber(double number) {
    String result;
    if (number >= 1000000) {
      result = '${(number / 1000000).toStringAsFixed(1)} م';
    } else if (number >= 1000) {
      result = '${(number / 1000).toStringAsFixed(1)} ك';
    } else {
      result = number.toStringAsFixed(2);
    }
    return NumberUtils.arabicToEnglishNumbers(result);
  }

  List<Map<String, dynamic>> _processMonthlyData(
    List<Transaction> transactions,
  ) {
    final Map<String, Map<String, double>> monthlyMap = {};

    for (var transaction in transactions) {
      final monthKey = NumberUtils.formatMonthYear(transaction.transactionDate);
      monthlyMap[monthKey] ??= {'income': 0, 'expense': 0};

      if (transaction.type == TransactionType.income) {
        monthlyMap[monthKey]!['income'] =
            (monthlyMap[monthKey]!['income'] ?? 0) + transaction.amount;
      } else {
        monthlyMap[monthKey]!['expense'] =
            (monthlyMap[monthKey]!['expense'] ?? 0) + transaction.amount;
      }
    }

    final List<Map<String, dynamic>> monthlyData = [];
    monthlyMap.forEach((month, data) {
      monthlyData.add({
        'month': month,
        'income': data['income'] ?? 0,
        'expense': data['expense'] ?? 0,
      });
    });

    monthlyData.sort((a, b) => a['month'].compareTo(b['month']));
    return monthlyData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer2<CategoryProvider, TransactionProvider>(
          builder: (context, categoryProvider, transactionProvider, _) {
            if (categoryProvider.isLoading || transactionProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final monthlyData = _processMonthlyData(
              transactionProvider.transactions,
            );

            double totalIncome = 0;
            double totalExpense = 0;
            for (var data in monthlyData) {
              totalIncome += data['income'] as double;
              totalExpense += data['expense'] as double;
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Add New Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'لوحة المعلومات',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddCategoryScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'إضافة فئة',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats Cards Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final isTablet = screenWidth > 600;
                        final isSmallScreen = screenWidth < 360;
                        
                        // Calculate responsive aspect ratio based on screen size
                        double aspectRatio;
                        if (isTablet) {
                          aspectRatio = 1.6; // More horizontal for tablets
                        } else if (isSmallScreen) {
                          aspectRatio = 1.1; // More vertical for small screens
                        } else {
                          aspectRatio = 1.25; // Balanced for medium screens
                        }
                        
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: isTablet ? 4 : 2,
                          mainAxisSpacing: isSmallScreen ? 12 : 16,
                          crossAxisSpacing: isSmallScreen ? 12 : 16,
                          childAspectRatio: aspectRatio,
                          children: [
                            _buildStatCard(
                              context: context,
                              title: 'فئات المصروفات',
                              value:
                                  '${categoryProvider.categories.where((cat) => cat.type == 'expense').length}',
                              change:
                                  '+${((categoryProvider.categories.where((cat) => cat.type == 'expense').length / (categoryProvider.categories.length)) * 100).toStringAsFixed(1)}%',
                              isPositive: true,
                              icon: Icons.category,
                              iconColor: Colors.red,
                            ),
                            _buildStatCard(
                              context: context,
                              title: 'فئات الإيرادات',
                              value:
                                  '${categoryProvider.categories.where((cat) => cat.type == 'income').length}',
                              change:
                                  '+${((categoryProvider.categories.where((cat) => cat.type == 'income').length / (categoryProvider.categories.length)) * 100).toStringAsFixed(1)}%',
                              isPositive: true,
                              icon: Icons.category,
                              iconColor: Colors.green,
                            ),
                            _buildStatCard(
                              context: context,
                              title: 'إجمالي المصروفات',
                              value: _formatCurrency(totalExpense),
                              change:
                                  '-${((totalExpense / (totalExpense + totalIncome)) * 100).toStringAsFixed(1)}%',
                              isPositive: false,
                              icon: Icons.money_off,
                              iconColor: Colors.red,
                            ),
                            _buildStatCard(
                              context: context,
                              title: 'إجمالي الإيرادات',
                              value: _formatCurrency(totalIncome),
                              change:
                                  '+${((totalIncome / (totalExpense + totalIncome)) * 100).toStringAsFixed(1)}%',
                              isPositive: true,
                              icon: Icons.attach_money,
                              iconColor: Colors.green,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Analytics Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ??
                            Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'تحليل المصروفات والإيرادات',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Period Selector
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _selectedPeriod,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          AnalysisChart(
                            monthlyData: monthlyData,
                            formatNumber: _formatLargeNumber,
                          ),
                          const SizedBox(height: 24),
                          FinancialSummary(
                            totalIncome: totalIncome,
                            totalExpense: totalExpense,
                            monthsCount: monthlyData.length,
                            formatCurrency: _formatCurrency,
                          ),
                        ],
                      ),
                    ),

                    // الملخص المالي
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الملخص المالي',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Consumer<TransactionProvider>(
                            builder: (context, transactionProvider, child) {
                              final totalIncome =
                                  transactionProvider.getTotalIncome();
                              final totalExpenses =
                                  transactionProvider.getTotalExpenses();
                              final balance = totalIncome - totalExpenses;

                              return Column(
                                children: [
                                  _buildSummaryRow(
                                    'الإيرادات',
                                    totalIncome,
                                    Colors.green,
                                    Icons.arrow_upward,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    'المصروفات',
                                    totalExpenses,
                                    Colors.red,
                                    Icons.arrow_downward,
                                  ),
                                  const Divider(),
                                  _buildSummaryRow(
                                    'الرصيد',
                                    balance,
                                    balance >= 0 ? Colors.green : Colors.red,
                                    balance >= 0
                                        ? Icons.account_balance
                                        : Icons.warning,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // قسم الأمنيات
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'الأمنيات والأهداف',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showAddWishDialog(context),
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة أمنية'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Consumer<WishesProvider>(
                            builder: (context, wishesProvider, child) {
                              final wishes = wishesProvider.wishes;
                              if (wishes.isEmpty) {
                                return Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.star_border,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'لا توجد أمنيات حالياً',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'أضف أمنياتك وابدأ في تحقيقها',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: wishes.length,
                                itemBuilder: (context, index) {
                                  return WishItem(wish: wishes[index]);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color iconColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final padding = isSmallScreen ? 12.0 : 16.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: isSmallScreen ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: isPositive ? Colors.green : Colors.red,
                          size: isSmallScreen ? 12 : 14,
                        ),
                        SizedBox(width: isSmallScreen ? 1 : 2),
                        Text(
                          change,
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            '${amount.toStringAsFixed(2)} ريال',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWishDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('إضافة أمنية جديدة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الأمنية',
                    hintText: 'مثال: سيارة جديدة',
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المستهدف',
                    hintText: 'أدخل المبلغ',
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty &&
                      amountController.text.isNotEmpty) {
                    final amount = double.tryParse(amountController.text);
                    if (amount != null && amount > 0) {
                      Provider.of<WishesProvider>(
                        context,
                        listen: false,
                      ).addWish(titleController.text, amount);
                      Navigator.of(ctx).pop();
                    }
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          ),
    );
  }
}
