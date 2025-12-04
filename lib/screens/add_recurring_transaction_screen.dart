import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recurring_transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/category_provider.dart';
import '../models/recurring_transaction.dart';
import '../models/account.dart';
import '../models/category.dart';

class AddRecurringTransactionScreen extends StatefulWidget {
  final RecurringTransaction? recurringTransaction;

  const AddRecurringTransactionScreen({super.key, this.recurringTransaction});

  @override
  State<AddRecurringTransactionScreen> createState() =>
      _AddRecurringTransactionScreenState();
}

class _AddRecurringTransactionScreenState
    extends State<AddRecurringTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _intervalController = TextEditingController(text: '1');
  final _maxOccurrencesController = TextEditingController();

  String? _selectedAccountId;
  String? _selectedCategoryId;
  RecurringFrequency _selectedFrequency = RecurringFrequency.monthly;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  RecurringStatus _status = RecurringStatus.active;

  bool _hasEndDate = false;
  bool _hasMaxOccurrences = false;

  @override
  void initState() {
    super.initState();
    if (widget.recurringTransaction != null) {
      _initializeWithExistingTransaction();
    }
  }

  void _initializeWithExistingTransaction() {
    final rt = widget.recurringTransaction!;
    _descriptionController.text = rt.description;
    _amountController.text = rt.amount.toString();
    _intervalController.text = rt.interval.toString();
    _selectedAccountId = rt.accountId;
    _selectedCategoryId = rt.categoryId;
    _selectedFrequency = rt.frequency;
    _startDate = rt.startDate;
    _endDate = rt.endDate;
    _status = rt.status;
    _hasEndDate = rt.endDate != null;
    _hasMaxOccurrences = rt.maxOccurrences != null;
    if (rt.maxOccurrences != null) {
      _maxOccurrencesController.text = rt.maxOccurrences.toString();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _intervalController.dispose();
    _maxOccurrencesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recurringTransaction == null
              ? 'إضافة معاملة متكررة'
              : 'تعديل معاملة متكررة',
        ),
        actions: [
          TextButton(
            onPressed: _saveRecurringTransaction,
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // الوصف
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'الوصف',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال الوصف';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // المبلغ
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                border: OutlineInputBorder(),
                prefixText: 'ر.س ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال المبلغ';
                }
                if (double.tryParse(value) == null) {
                  return 'يرجى إدخال مبلغ صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // الحساب
            Consumer<AccountProvider>(
              builder: (context, accountProvider, child) {
                return DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'الحساب',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      accountProvider.accounts.map((Account account) {
                        return DropdownMenuItem<String>(
                          value: account.id,
                          child: Text(account.name),
                        );
                      }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedAccountId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى اختيار الحساب';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // الفئة
            Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                return DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'الفئة',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      categoryProvider.categories.map((Category category) {
                        return DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى اختيار الفئة';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // التكرار
            DropdownButtonFormField<RecurringFrequency>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'التكرار',
                border: OutlineInputBorder(),
              ),
              items:
                  RecurringFrequency.values.map((RecurringFrequency frequency) {
                    return DropdownMenuItem<RecurringFrequency>(
                      value: frequency,
                      child: Text(_getFrequencyText(frequency)),
                    );
                  }).toList(),
              onChanged: (RecurringFrequency? value) {
                setState(() {
                  _selectedFrequency = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // الفترة
            TextFormField(
              controller: _intervalController,
              decoration: const InputDecoration(
                labelText: 'الفترة',
                border: OutlineInputBorder(),
                helperText: 'مثال: كل 2 أسابيع = 2',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال الفترة';
                }
                if (int.tryParse(value) == null || int.parse(value) < 1) {
                  return 'يرجى إدخال فترة صحيحة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // تاريخ البداية
            ListTile(
              title: const Text('تاريخ البداية'),
              subtitle: Text(_formatDate(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // تاريخ النهاية
            CheckboxListTile(
              title: const Text('تاريخ النهاية'),
              value: _hasEndDate,
              onChanged: (bool? value) {
                setState(() {
                  _hasEndDate = value ?? false;
                  if (!_hasEndDate) {
                    _endDate = null;
                  }
                });
              },
            ),
            if (_hasEndDate) ...[
              ListTile(
                title: const Text('تاريخ النهاية'),
                subtitle: Text(
                  _endDate != null
                      ? _formatDate(_endDate!)
                      : 'لم يتم اختيار تاريخ',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _endDate ?? _startDate.add(const Duration(days: 30)),
                    firstDate: _startDate,
                    lastDate: DateTime.now().add(
                      const Duration(days: 365 * 10),
                    ),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            // الحد الأقصى للمرات
            CheckboxListTile(
              title: const Text('الحد الأقصى للمرات'),
              value: _hasMaxOccurrences,
              onChanged: (bool? value) {
                setState(() {
                  _hasMaxOccurrences = value ?? false;
                  if (!_hasMaxOccurrences) {
                    _maxOccurrencesController.clear();
                  }
                });
              },
            ),
            if (_hasMaxOccurrences) ...[
              TextFormField(
                controller: _maxOccurrencesController,
                decoration: const InputDecoration(
                  labelText: 'الحد الأقصى للمرات',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الحد الأقصى للمرات';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 1) {
                    return 'يرجى إدخال عدد صحيح أكبر من 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // الحالة
            DropdownButtonFormField<RecurringStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'الحالة',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem<RecurringStatus>(
                  value: RecurringStatus.active,
                  child: Text('نشط'),
                ),
                DropdownMenuItem<RecurringStatus>(
                  value: RecurringStatus.paused,
                  child: Text('متوقف'),
                ),
              ],
              onChanged: (RecurringStatus? value) {
                setState(() {
                  _status = value!;
                });
              },
            ),
            const SizedBox(height: 32),

            // زر الحفظ
            ElevatedButton(
              onPressed: _saveRecurringTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.recurringTransaction == null
                    ? 'إضافة المعاملة المتكررة'
                    : 'تحديث المعاملة المتكررة',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _saveRecurringTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final recurringTransaction = RecurringTransaction(
        id: widget.recurringTransaction?.id,
        accountId: _selectedAccountId!,
        categoryId: _selectedCategoryId!,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text,
        frequency: _selectedFrequency,
        interval: int.parse(_intervalController.text),
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
        maxOccurrences:
            _hasMaxOccurrences
                ? int.parse(_maxOccurrencesController.text)
                : null,
        status: _status,
        userId: null, // TODO: إضافة معرف المستخدم
      );

      final provider = context.read<RecurringTransactionProvider>();

      if (widget.recurringTransaction == null) {
        await provider.addRecurringTransaction(recurringTransaction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة المعاملة المتكررة بنجاح')),
          );
        }
      } else {
        await provider.updateRecurringTransaction(recurringTransaction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث المعاملة المتكررة بنجاح')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في حفظ المعاملة المتكررة: $e')),
        );
      }
    }
  }
}
