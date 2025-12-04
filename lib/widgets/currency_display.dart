import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';

class CurrencyDisplay extends StatelessWidget {
  final double amount;
  final String currency;
  final double fontSize;
  final Color? textColor;

  const CurrencyDisplay({
    super.key,
    required this.amount,
    this.currency = 'ريال',
    this.fontSize = 24,
    this.textColor,
  });

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      '${_formatNumber(amount)} $currency',
      style: TextStyle(
        fontSize: fontSize,
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      minFontSize: 12,
      maxFontSize: fontSize,
    );
  }
}
