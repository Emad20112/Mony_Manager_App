import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/account.dart'; // تأكد من مسار النموذج الصحيح
import '../models/category.dart'; // تأكد من مسار النموذج الصحيح
import '../models/transaction.dart'; // تأكد من مسار النموذج الصحيح (خاصة TransactionType)
// استبدال استيراد الخدمات باستيراد Providers
// import '../services//account_service.dart'; // قم بإزالة هذا الاستيراد
// import '../services/category_service.dart'; // قم بإزالة هذا الاستيراد
// import '../services/transaction_service.dart'; // قم بإزالة هذا الاستيراد
import '../providers/account_provider.dart'; // تأكد من المسار الصحيح لـ AccountProvider
import '../providers/category_provider.dart'; // تأكد من المسار الصحيح لـ CategoryProvider
import '../providers/transaction_provider.dart'; // تأكد من المسار الصحيح لـ TransactionProvider
import 'add_category_screen.dart';
import '../utils/theme_extensions.dart'; // لألوان التصميم

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  TransactionType _selectedType = TransactionType.expense;
  Account? _selectedAccount;
  Category? _selectedCategory;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // استخدام الألوان من الثيم بدلاً من الألوان الثابتة

  // لم نعد بحاجة إلى Futures المحلية حيث سيتم إدارة البيانات بواسطة Providers
  // late Future<List<Account>> _accountsFuture;
  // late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );

      // تحميل الحسابات والفئات
      await accountProvider.fetchAccounts();
      await categoryProvider.fetchCategories(type: _selectedType.name);

      // التحقق من وجود بيانات
      if (mounted) {
        if (accountProvider.accounts.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا توجد حسابات متاحة. الرجاء إضافة حساب أولاً.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop();
          return;
        }

        final categories =
            categoryProvider.categories
                .where((cat) => cat.type == _selectedType.name)
                .toList();

        if (categories.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا توجد فئات متاحة. الرجاء إضافة فئة أولاً.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop();
          return;
        }

        // تعيين القيم الافتراضية
        setState(() {
          // Use the selected account from the provider if available, otherwise first account
          _selectedAccount =
              accountProvider.selectedAccount ?? accountProvider.accounts.first;
          if (categories.isNotEmpty) {
            _selectedCategory = categories.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  // تحديث دالة _updateCategoryList
  void _updateCategoryList(TransactionType type) async {
    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );

      await categoryProvider.fetchCategories(type: type.name);

      if (mounted) {
        final categories =
            categoryProvider.categories
                .where((cat) => cat.type == type.name)
                .toList();

        print('Found ${categories.length} categories for type ${type.name}');
        categories.forEach(
          (cat) =>
              print('Category: ${cat.name}, ID: ${cat.id}, Type: ${cat.type}'),
        );

        setState(() {
          // إعادة تعيين الفئة المحددة إذا كانت الفئات غير فارغة
          if (categories.isNotEmpty) {
            _selectedCategory = categories.first;
          } else {
            _selectedCategory = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحميل الفئات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // التحقق من اختيار الحساب والفئة
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار الحساب'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار الفئة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال مبلغ صحيح'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // التأكد من وجود قيم صحيحة قبل إنشاء المعاملة
      final accountId = _selectedAccount!.id;
      final categoryId = _selectedCategory!.id;

      // Debug logging
      print('Creating transaction with:');
      print('Account: ${_selectedAccount!.name}, ID: $accountId');
      print('Category: ${_selectedCategory!.name}, ID: $categoryId');
      print('Amount: $amount');
      print('Type: $_selectedType');

      if (accountId == null) {
        throw Exception('خطأ في البيانات: الحساب غير محدد');
      }

      if (categoryId == null) {
        throw Exception('خطأ في البيانات: الفئة غير محددة');
      }

      final newTransaction = Transaction(
        accountId: accountId,
        categoryId: categoryId,
        amount: amount,
        type: _selectedType,
        description:
            _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
        transactionDate: _selectedDate,
        userId: 'default_user',
      );

      print('Transaction object created: $newTransaction');
      await transactionProvider.addTransaction(newTransaction, context);

      if (!mounted) return;

      // Close loading indicator
      Navigator.of(context).pop();

      // Show success message and return
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة المعاملة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      // Close loading indicator if it's showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error adding transaction: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في إضافة المعاملة: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'حسناً',
            textColor: Colors.white,
            onPressed: () {
              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة معاملة جديدة'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Consumer3<AccountProvider, CategoryProvider, TransactionProvider>(
        builder: (
          context,
          accountProvider,
          categoryProvider,
          transactionProvider,
          child,
        ) {
          // تحديث الحساب المحدد إذا كان فارغاً
          if (_selectedAccount == null && accountProvider.accounts.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedAccount = accountProvider.accounts.first;
              });
            });
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // نوع المعاملة
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Theme.of(context).cardTheme.color ??
                          Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = TransactionType.expense;
                                _updateCategoryList(_selectedType);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(30),
                                ),
                                color:
                                    _selectedType == TransactionType.expense
                                        ? Theme.of(context).expenseColor
                                        : Colors.grey[300],
                              ),
                              child: Center(
                                child: Text(
                                  'مصروف',
                                  style: TextStyle(
                                    color:
                                        _selectedType == TransactionType.expense
                                            ? Colors.white
                                            : Theme.of(context).textTheme.titleMedium?.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = TransactionType.income;
                                _updateCategoryList(_selectedType);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(30),
                                ),
                                color:
                                    _selectedType == TransactionType.income
                                        ? Theme.of(context).incomeColor
                                        : Colors.grey[300],
                              ),
                              child: Center(
                                child: Text(
                                  'دخل',
                                  style: TextStyle(
                                    color:
                                        _selectedType == TransactionType.income
                                            ? Colors.white
                                            : Theme.of(context).textTheme.titleMedium?.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // قائمة الحسابات المنسدلة
                  if (accountProvider.accounts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'لا توجد حسابات متاحة',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  else
                    DropdownButtonFormField<Account>(
                      value: _selectedAccount ?? accountProvider.accounts.first,
                      decoration: InputDecoration(
                        labelText: 'الحساب',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                      ),
                      items:
                          accountProvider.accounts.map((Account account) {
                            return DropdownMenuItem<Account>(
                              value: account,
                              child: Text(
                                account.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          }).toList(),
                      onChanged: (Account? newValue) {
                        setState(() {
                          _selectedAccount = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'الرجاء اختيار حساب';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 16.0),

                  // Category Dropdown - استخدم Consumer لـ CategoryProvider
                  Consumer<CategoryProvider>(
                    builder: (context, categoryProvider, child) {
                      if (categoryProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final categories =
                          categoryProvider.categories
                              .where((cat) => cat.type == _selectedType.name)
                              .toList();

                      if (categories.isEmpty) {
                        return Column(
                          children: [
                            Text(
                              'لا توجد فئات متاحة لـ ${_selectedType == TransactionType.expense ? 'المصروفات' : 'الدخل'}.',
                              style: const TextStyle(color: Colors.orange),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const AddCategoryScreen(),
                                  ),
                                ).then((_) {
                                  _updateCategoryList(_selectedType);
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة فئة جديدة'),
                            ),
                          ],
                        );
                      }

                      // تعيين فئة افتراضية إذا لم تكن محددة أو إذا كانت الفئة المحددة لا تنتمي لنوع المعاملة الحالي
                      if (_selectedCategory == null ||
                          !categories.contains(_selectedCategory)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _selectedCategory = categories.first;
                          });
                        });
                      }

                      return DropdownButtonFormField<Category>(
                        value:
                            categories.contains(_selectedCategory)
                                ? _selectedCategory
                                : (categories.isNotEmpty
                                    ? categories.first
                                    : null),
                        hint: const Text('اختر الفئة'),
                        items:
                            categories.map((Category category) {
                              return DropdownMenuItem<Category>(
                                value: category,
                                child: Text(category.name),
                              );
                            }).toList(),
                        onChanged: (Category? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          }
                        },
                        validator:
                            (value) => value == null ? 'الفئة مطلوبة' : null,
                        decoration: InputDecoration(
                          labelText: 'الفئة',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                          prefixIcon: Icon(
                            Icons.category,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Amount Field (لا يتفاعل مباشرة مع Providers، يبقى كما هو)
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'المبلغ',
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'المبلغ مطلوب';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'الرجاء إدخال مبلغ صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Description Field (لا يتفاعل مباشرة مع Providers، يبقى كما هو)
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'الوصف (اختياري)',
                      prefixIcon: Icon(
                        Icons.description,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16.0),

                  // Date Picker (لا يتفاعل مباشرة مع Providers، يبقى كما هو)
                  ListTile(
                    title: Text(
                      'التاريخ: ${DateFormat('yyyy/MM/dd').format(_selectedDate)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 24.0),

                  // Submit Button - استخدم Consumer لـ TransactionProvider لعرض حالة التحميل
                  Consumer<TransactionProvider>(
                    builder: (context, transactionProvider, child) {
                      // عرض مؤشر التحميل على الزر وتعطيله إذا كان isLoading صحيحًا
                      return ElevatedButton.icon(
                        icon:
                            transactionProvider.isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.save),
                        label: const Text('حفظ المعاملة'),
                        onPressed:
                            transactionProvider.isLoading
                                ? null
                                : _submitForm, // تعطيل الزر عند التحميل
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      );
                    },
                  ),
                  // يمكنك عرض رسالة خطأ TransactionProvider هنا إذا لزم الأمر
                  Consumer<TransactionProvider>(
                    builder: (context, transactionProvider, child) {
                      if (transactionProvider.errorMessage != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            transactionProvider.errorMessage!,
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
