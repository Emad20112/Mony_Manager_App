import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../providers/account_provider.dart';
import '../providers/category_provider.dart';
import '../providers/list_extensions.dart';
import '../utils/theme_extensions.dart'; // لألوان التصميم

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المعاملة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit transaction screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ميزة التعديل قيد التطوير')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: Consumer2<AccountProvider, CategoryProvider>(
        builder: (context, accountProvider, categoryProvider, child) {
          final account = accountProvider.accounts.firstWhereOrNull(
            (a) => a.id == transaction.accountId,
          );
          final category = categoryProvider.categories.firstWhereOrNull(
            (c) => c.id == transaction.categoryId,
          );
          final toAccount =
              transaction.toAccountId != null
                  ? accountProvider.accounts.firstWhereOrNull(
                    (a) => a.id == transaction.toAccountId,
                  )
                  : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction Type Card
                _buildTypeCard(context),
                const SizedBox(height: 16),

                // Amount Card
                _buildAmountCard(context),
                const SizedBox(height: 16),

                // Details Card
                _buildDetailsCard(context, account, category, toAccount),
                const SizedBox(height: 16),

                // Date and Time Card
                _buildDateTimeCard(context),
                const SizedBox(height: 16),

                // Additional Info Card (if available)
                if (transaction.metadata != null || transaction.isRecurring)
                  _buildAdditionalInfoCard(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final isIncome = transaction.type == TransactionType.income;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (isExpense
                        ? Theme.of(context).expenseColor
                        : isIncome
                        ? Theme.of(context).incomeColor
                        : Theme.of(context).colorScheme.primary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                isExpense
                    ? Icons.arrow_downward
                    : isIncome
                    ? Icons.arrow_upward
                    : Icons.swap_horiz,
                color:
                    isExpense
                        ? Theme.of(context).expenseColor
                        : isIncome
                        ? Theme.of(context).incomeColor
                        : Theme.of(context).colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isExpense
                        ? 'مصروف'
                        : isIncome
                        ? 'إيراد'
                        : 'تحويل',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isExpense
                              ? Theme.of(context).expenseColor
                              : isIncome
                              ? Theme.of(context).incomeColor
                              : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    transaction.status == 'completed'
                        ? 'مكتملة'
                        : transaction.status == 'pending'
                        ? 'معلقة'
                        : 'ملغية',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final isIncome = transaction.type == TransactionType.income;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المبلغ',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
            ),
            const SizedBox(height: 8),
            Text(
              '${isExpense
                  ? '-'
                  : isIncome
                  ? '+'
                  : ''} ${_formatCurrency(transaction.amount.abs())}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color:
                    isExpense
                        ? Theme.of(context).expenseColor
                        : isIncome
                        ? Theme.of(context).incomeColor
                        : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    Account? account,
    Category? category,
    Account? toAccount,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التفاصيل',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'الحساب',
              account?.name ?? 'غير محدد',
              Icons.account_balance_wallet,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              'الفئة',
              category?.name ?? 'غير محدد',
              Icons.category,
            ),
            if (transaction.toAccountId != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'إلى الحساب',
                toAccount?.name ?? 'غير محدد',
                Icons.account_balance,
              ),
            ],
            if (transaction.description != null &&
                transaction.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'الوصف',
                transaction.description!,
                Icons.description,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6) ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التاريخ والوقت',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'تاريخ المعاملة',
              DateFormat(
                'dd MMMM yyyy',
                'ar',
              ).format(transaction.transactionDate),
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              'وقت المعاملة',
              DateFormat('hh:mm a', 'ar').format(transaction.transactionDate),
              Icons.access_time,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              'تاريخ الإنشاء',
              DateFormat(
                'dd MMMM yyyy, hh:mm a',
                'ar',
              ).format(transaction.createdAt),
              Icons.add_circle_outline,
            ),
            if (transaction.updatedAt != transaction.createdAt) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'آخر تحديث',
                DateFormat(
                  'dd MMMM yyyy, hh:mm a',
                  'ar',
                ).format(transaction.updatedAt),
                Icons.update,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات إضافية',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (transaction.isRecurring) ...[
              _buildDetailRow(context, 'معاملة متكررة', 'نعم', Icons.repeat),
              if (transaction.recurringRuleId != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  context,
                  'معرف القاعدة',
                  transaction.recurringRuleId!,
                  Icons.rule,
                ),
              ],
            ],
            if (transaction.metadata != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'بيانات إضافية',
                transaction.metadata!,
                Icons.info_outline,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'ar_YE', symbol: 'ريال');
    return format.format(amount);
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text(
            'هل أنت متأكد من رغبتك في حذف هذه المعاملة؟ لا يمكن التراجع عن هذا الإجراء.',
          ),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('حذف', style: TextStyle(color: Theme.of(context).expenseColor)),
              onPressed: () {
                // TODO: Implement delete transaction
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ميزة الحذف قيد التطوير')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
