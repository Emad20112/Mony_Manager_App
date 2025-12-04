import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/number_utils.dart';

class AnalysisChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;
  final Function(double) formatNumber;

  const AnalysisChart({
    super.key,
    required this.monthlyData,
    required this.formatNumber,
  });

  DateTime _parseMonthYear(String monthStr) {
    try {
      final year = int.parse(monthStr.substring(0, 4));
      final month = int.parse(monthStr.substring(5, 7));
      return DateTime(year, month);
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];
    final theme = Theme.of(context);

    // Custom colors
    final incomeColor = Color(0xFF2ECC71);
    final expenseColor = Color(0xFFE74C3C);

    for (int i = 0; i < monthlyData.length; i++) {
      final data = monthlyData[i];
      incomeSpots.add(FlSpot(i.toDouble(), data['income'] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), data['expense'] ?? 0));
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1000,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme.dividerColor.withAlpha((0.15 * 255).round()),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          formatNumber(value),
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < monthlyData.length) {
                        final monthStr =
                            monthlyData[value.toInt()]['month'] as String;
                        final date = _parseMonthYear(monthStr);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat.MMM('ar').format(date),
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withAlpha((0.2 * 255).round()),
                    width: 1,
                  ),
                  left: BorderSide(
                    color: theme.dividerColor.withAlpha((0.2 * 255).round()),
                    width: 1,
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  color: expenseColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: expenseColor,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        expenseColor.withAlpha((0.2 * 255).round()),
                        expenseColor.withAlpha((0.05 * 255).round()),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  color: incomeColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: incomeColor,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        incomeColor.withAlpha((0.2 * 255).round()),
                        incomeColor.withAlpha((0.05 * 255).round()),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBorderRadius: BorderRadius.circular(8),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      final isIncome = touchedSpot.barIndex == 1;
                      final date =
                          monthlyData[touchedSpot.x.toInt()]['month'] as String;
                      final parsedDate = _parseMonthYear(date);
                      final formattedDate = DateFormat.yMMMM(
                        'ar',
                      ).format(parsedDate);

                      return LineTooltipItem(
                        '$formattedDate\n${isIncome ? "الإيرادات" : "المصروفات"}\n${formatNumber(touchedSpot.y)} ريال',
                        TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.right,
                      );
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
                touchCallback:
                    (FlTouchEvent event, LineTouchResponse? response) {},
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('الإيرادات', incomeColor),
            const SizedBox(width: 24),
            _buildLegendItem('المصروفات', expenseColor),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withAlpha((0.2 * 255).round()),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
