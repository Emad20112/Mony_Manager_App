import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Not used
import 'package:fl_chart/fl_chart.dart';
// import '../providers/language_provider.dart'; // Not used
import '../services/reports_service.dart';
import '../l10n/app_localizations.dart';

class AdvancedReportsScreen extends StatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  State<AdvancedReportsScreen> createState() => _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends State<AdvancedReportsScreen>
    with TickerProviderStateMixin {
  final ReportsService _reportsService = ReportsService();
  late TabController _tabController;

  DateTime _selectedMonth = DateTime.now();
  int _selectedYear = DateTime.now().year;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final languageProvider = context.watch<LanguageProvider>(); // Not used
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.monthly),
            Tab(text: l10n.yearly),
            Tab(text: l10n.category),
            const Tab(text: 'Patterns'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonthlyReport(l10n),
          _buildYearlyReport(l10n),
          _buildCategoryReport(l10n),
          _buildPatternsReport(l10n),
        ],
      ),
    );
  }

  Widget _buildMonthlyReport(AppLocalizations l10n) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportsService.getMonthlySpendingReport(month: _selectedMonth),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthSelector(l10n),
              const SizedBox(height: 20),
              _buildSummaryCards(data, l10n),
              const SizedBox(height: 20),
              _buildCategoryChart(data['categoryBreakdown'], l10n),
              const SizedBox(height: 20),
              _buildCategoryList(data['categoryBreakdown'], l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearlyReport(AppLocalizations l10n) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportsService.getYearlySpendingReport(year: _selectedYear),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildYearSelector(l10n),
              const SizedBox(height: 20),
              _buildYearlySummaryCards(data, l10n),
              const SizedBox(height: 20),
              _buildMonthlyChart(data['monthlyBreakdown'], l10n),
              const SizedBox(height: 20),
              _buildMonthlyList(data['monthlyBreakdown'], l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryReport(AppLocalizations l10n) {
    return const Center(child: Text('Category Report - Coming Soon'));
  }

  Widget _buildPatternsReport(AppLocalizations l10n) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportsService.getSpendingPatternsReport(
        startDate: _startDate,
        endDate: _endDate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateRangeSelector(l10n),
              const SizedBox(height: 20),
              _buildDayOfWeekChart(data['dayOfWeekBreakdown'], l10n),
              const SizedBox(height: 20),
              _buildHourOfDayChart(data['hourOfDayBreakdown'], l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector(AppLocalizations l10n) {
    return Card(
      child: ListTile(
        title: Text('${_selectedMonth.year}/${_selectedMonth.month}'),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedMonth,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() {
              _selectedMonth = date;
            });
          }
        },
      ),
    );
  }

  Widget _buildYearSelector(AppLocalizations l10n) {
    return Card(
      child: ListTile(
        title: Text(_selectedYear.toString()),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final year = await showDialog<int>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('Select Year'),
                  content: SizedBox(
                    width: 200,
                    height: 300,
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        final year = DateTime.now().year - index;
                        return ListTile(
                          title: Text(year.toString()),
                          onTap: () => Navigator.pop(context, year),
                        );
                      },
                    ),
                  ),
                ),
          );
          if (year != null) {
            setState(() {
              _selectedYear = year;
            });
          }
        },
      ),
    );
  }

  Widget _buildDateRangeSelector(AppLocalizations l10n) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              'From: ${_startDate.toLocal().toString().split(' ')[0]}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2020),
                lastDate: _endDate,
              );
              if (date != null) {
                setState(() {
                  _startDate = date;
                });
              }
            },
          ),
          ListTile(
            title: Text('To: ${_endDate.toLocal().toString().split(' ')[0]}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _endDate,
                firstDate: _startDate,
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _endDate = date;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> data, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${data['totalSpent']?.toStringAsFixed(2) ?? '0.00'} SAR',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(l10n.totalExpenses),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${data['transactionCount'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Transactions'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearlySummaryCards(
    Map<String, dynamic> data,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${data['totalSpent']?.toStringAsFixed(2) ?? '0.00'} SAR',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(l10n.totalExpenses),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${data['averageMonthlySpending']?.toStringAsFixed(2) ?? '0.00'} SAR',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Avg/Month'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart(List<dynamic> categories, AppLocalizations l10n) {
    if (categories.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No data available')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections:
                      categories.take(5).map((category) {
                        return PieChartSectionData(
                          value: category['amount'] as double,
                          title: category['categoryName'] as String,
                          color:
                              Colors.primaries[categories.indexOf(category) %
                                  Colors.primaries.length],
                          radius: 100,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(List<dynamic> months, AppLocalizations l10n) {
    if (months.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No data available')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Spending',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups:
                      months.map((month) {
                        return BarChartGroupData(
                          x: month['month'] as int,
                          barRods: [
                            BarChartRodData(
                              toY: month['amount'] as double,
                              color: Colors.blue,
                              width: 16,
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayOfWeekChart(List<dynamic> days, AppLocalizations l10n) {
    if (days.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No data available')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Day of Week',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups:
                      days.map((day) {
                        return BarChartGroupData(
                          x: day['day'] as int,
                          barRods: [
                            BarChartRodData(
                              toY: day['amount'] as double,
                              color: Colors.green,
                              width: 16,
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourOfDayChart(List<dynamic> hours, AppLocalizations l10n) {
    if (hours.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No data available')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Hour of Day',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups:
                      hours.where((hour) => hour['amount'] > 0).map((hour) {
                        return BarChartGroupData(
                          x: hour['hour'] as int,
                          barRods: [
                            BarChartRodData(
                              toY: hour['amount'] as double,
                              color: Colors.orange,
                              width: 8,
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<dynamic> categories, AppLocalizations l10n) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ...categories.map((category) {
            return ListTile(
              title: Text(category['categoryName'] as String),
              subtitle: Text(
                '${category['percentage']?.toStringAsFixed(1) ?? '0.0'}%',
              ),
              trailing: Text(
                '${category['amount']?.toStringAsFixed(2) ?? '0.00'} SAR',
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMonthlyList(List<dynamic> months, AppLocalizations l10n) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Monthly Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ...months.map((month) {
            return ListTile(
              title: Text(month['monthName'] as String),
              trailing: Text(
                '${month['amount']?.toStringAsFixed(2) ?? '0.00'} SAR',
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
