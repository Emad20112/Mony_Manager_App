import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recurring_transaction_provider.dart';
import '../models/recurring_transaction.dart';
import 'add_recurring_transaction_screen.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecurringTransactionProvider>().loadRecurringTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المعاملات المتكررة'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String status) {
              setState(() {
                _selectedStatus = status;
              });
              _loadRecurringTransactionsByStatus(status);
            },
            itemBuilder:
                (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'all',
                    child: Text('الكل'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'active',
                    child: Text('نشط'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'paused',
                    child: Text('متوقف'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'completed',
                    child: Text('مكتمل'),
                  ),
                ],
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Consumer<RecurringTransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      _loadRecurringTransactionsByStatus(_selectedStatus);
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (provider.recurringTransactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد معاملات متكررة',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'اضغط على + لإضافة معاملة متكررة',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.recurringTransactions.length,
            itemBuilder: (context, index) {
              final recurringTransaction =
                  provider.recurringTransactions[index];
              return _buildRecurringTransactionCard(
                recurringTransaction,
                provider,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRecurringTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecurringTransactionCard(
    RecurringTransaction recurringTransaction,
    RecurringTransactionProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(recurringTransaction.status),
          child: Icon(
            _getStatusIcon(recurringTransaction.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          recurringTransaction.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المبلغ: ${recurringTransaction.amount.toStringAsFixed(2)}'),
            Text(
              'التكرار: ${_getFrequencyText(recurringTransaction.frequency)}',
            ),
            Text('الحالة: ${_getStatusText(recurringTransaction.status)}'),
            if (recurringTransaction.lastExecuted != null)
              Text(
                'آخر تنفيذ: ${_formatDate(recurringTransaction.lastExecuted!)}',
              ),
            Text('عدد المرات المنفذة: ${recurringTransaction.executedCount}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String action) {
            _handleAction(action, recurringTransaction, provider);
          },
          itemBuilder:
              (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'execute',
                  child: Text('تنفيذ الآن'),
                ),
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('تعديل'),
                ),
                const PopupMenuItem<String>(
                  value: 'pause',
                  child: Text('إيقاف'),
                ),
                const PopupMenuItem<String>(
                  value: 'resume',
                  child: Text('استئناف'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('حذف'),
                ),
              ],
        ),
        onTap: () {
          _showRecurringTransactionDetails(recurringTransaction);
        },
      ),
    );
  }

  Color _getStatusColor(RecurringStatus status) {
    switch (status) {
      case RecurringStatus.active:
        return Colors.green;
      case RecurringStatus.paused:
        return Colors.orange;
      case RecurringStatus.completed:
        return Colors.blue;
      case RecurringStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(RecurringStatus status) {
    switch (status) {
      case RecurringStatus.active:
        return Icons.play_arrow;
      case RecurringStatus.paused:
        return Icons.pause;
      case RecurringStatus.completed:
        return Icons.check;
      case RecurringStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(RecurringStatus status) {
    switch (status) {
      case RecurringStatus.active:
        return 'نشط';
      case RecurringStatus.paused:
        return 'متوقف';
      case RecurringStatus.completed:
        return 'مكتمل';
      case RecurringStatus.cancelled:
        return 'ملغي';
    }
  }

  String _getFrequencyText(RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return 'يومي';
      case RecurringFrequency.weekly:
        return 'أسبوعي';
      case RecurringFrequency.monthly:
        return 'شهري';
      case RecurringFrequency.yearly:
        return 'سنوي';
      case RecurringFrequency.custom:
        return 'مخصص';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleAction(
    String action,
    RecurringTransaction recurringTransaction,
    RecurringTransactionProvider provider,
  ) {
    switch (action) {
      case 'execute':
        _executeRecurringTransaction(recurringTransaction, provider);
        break;
      case 'edit':
        _editRecurringTransaction(recurringTransaction);
        break;
      case 'pause':
        _pauseRecurringTransaction(recurringTransaction, provider);
        break;
      case 'resume':
        _resumeRecurringTransaction(recurringTransaction, provider);
        break;
      case 'delete':
        _deleteRecurringTransaction(recurringTransaction, provider);
        break;
    }
  }

  void _executeRecurringTransaction(
    RecurringTransaction recurringTransaction,
    RecurringTransactionProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تنفيذ المعاملة المتكررة'),
          content: const Text('هل تريد تنفيذ هذه المعاملة المتكررة الآن؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await provider.executeRecurringTransaction(
                    recurringTransaction,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تنفيذ المعاملة بنجاح')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل في تنفيذ المعاملة: $e')),
                    );
                  }
                }
              },
              child: const Text('تنفيذ'),
            ),
          ],
        );
      },
    );
  }

  void _editRecurringTransaction(RecurringTransaction recurringTransaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddRecurringTransactionScreen(
              recurringTransaction: recurringTransaction,
            ),
      ),
    );
  }

  void _pauseRecurringTransaction(
    RecurringTransaction recurringTransaction,
    RecurringTransactionProvider provider,
  ) async {
    try {
      final pausedTransaction = recurringTransaction.copyWith(
        status: RecurringStatus.paused,
        updatedAt: DateTime.now(),
      );
      await provider.updateRecurringTransaction(pausedTransaction);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إيقاف المعاملة المتكررة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في إيقاف المعاملة: $e')));
      }
    }
  }

  void _resumeRecurringTransaction(
    RecurringTransaction recurringTransaction,
    RecurringTransactionProvider provider,
  ) async {
    try {
      final resumedTransaction = recurringTransaction.copyWith(
        status: RecurringStatus.active,
        updatedAt: DateTime.now(),
      );
      await provider.updateRecurringTransaction(resumedTransaction);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم استئناف المعاملة المتكررة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في استئناف المعاملة: $e')));
      }
    }
  }

  void _deleteRecurringTransaction(
    RecurringTransaction recurringTransaction,
    RecurringTransactionProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('حذف المعاملة المتكررة'),
          content: const Text('هل أنت متأكد من حذف هذه المعاملة المتكررة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await provider.deleteRecurringTransaction(
                    recurringTransaction.id!,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حذف المعاملة المتكررة')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل في حذف المعاملة: $e')),
                    );
                  }
                }
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  void _showRecurringTransactionDetails(
    RecurringTransaction recurringTransaction,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تفاصيل المعاملة المتكررة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الوصف: ${recurringTransaction.description}'),
              Text('المبلغ: ${recurringTransaction.amount.toStringAsFixed(2)}'),
              Text(
                'التكرار: ${_getFrequencyText(recurringTransaction.frequency)}',
              ),
              Text('الفترة: ${recurringTransaction.interval}'),
              Text(
                'تاريخ البداية: ${_formatDate(recurringTransaction.startDate)}',
              ),
              if (recurringTransaction.endDate != null)
                Text(
                  'تاريخ النهاية: ${_formatDate(recurringTransaction.endDate!)}',
                ),
              if (recurringTransaction.maxOccurrences != null)
                Text(
                  'الحد الأقصى للمرات: ${recurringTransaction.maxOccurrences}',
                ),
              Text('الحالة: ${_getStatusText(recurringTransaction.status)}'),
              if (recurringTransaction.lastExecuted != null)
                Text(
                  'آخر تنفيذ: ${_formatDate(recurringTransaction.lastExecuted!)}',
                ),
              Text('عدد المرات المنفذة: ${recurringTransaction.executedCount}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  void _loadRecurringTransactionsByStatus(String status) {
    final provider = context.read<RecurringTransactionProvider>();
    if (status == 'all') {
      provider.loadRecurringTransactions();
    } else {
      RecurringStatus? recurringStatus;
      switch (status) {
        case 'active':
          recurringStatus = RecurringStatus.active;
          break;
        case 'paused':
          recurringStatus = RecurringStatus.paused;
          break;
        case 'completed':
          recurringStatus = RecurringStatus.completed;
          break;
      }
      provider.loadRecurringTransactions(status: recurringStatus);
    }
  }
}
