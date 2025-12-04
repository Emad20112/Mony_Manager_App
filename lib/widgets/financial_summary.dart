import 'package:flutter/material.dart';

class FinancialSummary extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final int monthsCount;
  final Function(double) formatCurrency;

  const FinancialSummary({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.monthsCount,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final double balance = totalIncome - totalExpense;
    final double savingsRate =
        totalIncome > 0 ? ((balance) / totalIncome) * 100 : 0;
    final double monthlyAvgIncome =
        monthsCount > 0 ? totalIncome / monthsCount : 0;
    final double monthlyAvgExpense =
        monthsCount > 0 ? totalExpense / monthsCount : 0;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ملخص مالي',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'آخر $monthsCount أشهر',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withAlpha((0.05 * 255).round()),
                theme.colorScheme.primary.withAlpha((0.02 * 255).round()),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildMainStat(
                context,
                'الرصيد الحالي',
                balance,
                balance >= 0
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFFE74C3C),
                Icons.account_balance_wallet,
              ),
              _buildDivider(),
              _buildSavingsRateCard(context, savingsRate),
              _buildDivider(),
              Row(
                children: [
                  Expanded(
                    child: _buildAverageStat(
                      context,
                      'متوسط الإيرادات',
                      monthlyAvgIncome,
                      const Color(0xFF2ECC71),
                      Icons.arrow_upward,
                    ),
                  ),
                  Container(
                    height: 65,
                    width: 1,
                    color: theme.dividerColor.withAlpha((0.1 * 255).round()),
                  ),
                  Expanded(
                    child: _buildAverageStat(
                      context,
                      'متوسط المصروفات',
                      monthlyAvgExpense,
                      const Color(0xFFE74C3C),
                      Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainStat(
    BuildContext context,
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(value),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsRateCard(BuildContext context, double savingsRate) {
    final color =
        savingsRate >= 0 ? const Color(0xFF3498DB) : const Color(0xFFE67E22);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.savings, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نسبة التوفير',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${savingsRate.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      savingsRate >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: color,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageStat(
    BuildContext context,
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(value),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.withAlpha((0.1 * 255).round()),
    );
  }
}
