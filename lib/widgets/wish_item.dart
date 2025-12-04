import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wish.dart';
import '../providers/wishes_provider.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class WishItem extends StatelessWidget {
  final Wish wish;

  const WishItem({super.key, required this.wish});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    wish.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    Provider.of<WishesProvider>(
                      context,
                      listen: false,
                    ).deleteWish(wish.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: wish.savedAmount / wish.targetAmount,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المبلغ المدخر: ${wish.savedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'الهدف: ${wish.targetAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: () => _showAddAmountDialog(context),
                child: const Text('إضافة مبلغ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAmountDialog(BuildContext context) {
    final amountController = TextEditingController();
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final accounts = accountProvider.accounts;
    String? selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('إضافة مبلغ للأمنية'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // حقل اختيار الحساب
                      DropdownButtonFormField<String>(
                        value: selectedAccountId,
                        decoration: const InputDecoration(
                          labelText: 'اختر الحساب',
                        ),
                        items:
                            accounts.map((account) {
                              return DropdownMenuItem<String>(
                                value: account.id,
                                child: Text(
                                  '${account.name} (${account.balance.toStringAsFixed(2)})',
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedAccountId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // حقل إدخال المبلغ
                      TextField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'المبلغ',
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
                      onPressed: () async {
                        if (amountController.text.isNotEmpty &&
                            selectedAccountId != null) {
                          final amount = double.tryParse(amountController.text);
                          if (amount != null && amount > 0) {
                            final selectedAccount = accounts.firstWhere(
                              (account) => account.id == selectedAccountId,
                            );

                            if (amount <= selectedAccount.balance) {
                              try {
                                // إنشاء معاملة جديدة
                                final transaction = Transaction(
                                  accountId: selectedAccountId!,
                                  categoryId:
                                      '1', // يجب إنشاء فئة خاصة للأمنيات
                                  amount: amount,
                                  type: TransactionType.expense,
                                  description: 'مدخرات لـ ${wish.title}',
                                  transactionDate: DateTime.now(),
                                  userId: 'default_user',
                                );

                                // إضافة المعاملة
                                await Provider.of<TransactionProvider>(
                                  context,
                                  listen: false,
                                ).addTransaction(transaction, context);

                                // إضافة المبلغ للأمنية
                                await Provider.of<WishesProvider>(
                                  context,
                                  listen: false,
                                ).addAmountToWish(wish.id, amount);

                                Navigator.of(ctx).pop();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم إضافة المبلغ بنجاح'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('حدث خطأ: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('رصيد الحساب غير كافي'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('إضافة'),
                    ),
                  ],
                ),
          ),
    );
  }
}
