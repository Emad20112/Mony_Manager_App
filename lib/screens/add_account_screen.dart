import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';
import '../utils/currency_list.dart';
import '../utils/theme_extensions.dart'; // لألوان التصميم

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  String _selectedAccountType = 'cash';
  String _selectedCurrency = availableCurrencies.first;
  // استخدام الألوان من الثيم بدلاً من الألوان الثابتة

  final Map<String, IconData> _accountTypeIcons = {
    'cash': Icons.money,
    'bank': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'savings': Icons.savings,
    'investment': Icons.trending_up,
    'other': Icons.account_balance_wallet,
  };

  final Map<String, String> _accountTypeNames = {
    'cash': 'نقدي',
    'bank': 'حساب بنكي',
    'credit_card': 'بطاقة ائتمان',
    'savings': 'حساب توفير',
    'investment': 'استثمار',
    'other': 'آخر',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      try {
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );
        final initialBalance =
            double.tryParse(_initialBalanceController.text.trim()) ?? 0.0;

        final newAccount = Account(
          name: _nameController.text.trim(),
          type: _selectedAccountType,
          balance: initialBalance,
          currency: _selectedCurrency,
          userId: 'default_user', // إضافة userId مطلوب
        );

        await accountProvider.addAccount(newAccount);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تمت إضافة الحساب بنجاح'),
              ],
            ),
            backgroundColor: Theme.of(context).incomeColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(8),
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('حدث خطأ: ${e.toString()}')),
              ],
            ),
            backgroundColor: Theme.of(context).expenseColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(8),
          ),
        );
      }
    }
  }

  Widget _buildAccountTypeSelector() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            _accountTypeIcons.entries.map((entry) {
              final bool isSelected = _selectedAccountType == entry.key;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAccountType = entry.key;
                  });
                },
                child: Container(
                  width: 100,
                  margin: EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.withAlpha((0.3 * 255).round()),
                      width: 2,
                    ),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withAlpha(
                                  (0.3 * 255).round(),
                                ),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ]
                            : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        entry.value,
                        size: 32,
                        color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _accountTypeNames[entry.key]!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('إضافة حساب جديد'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Text(
                'أدخل معلومات حسابك الجديد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'نوع الحساب',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildAccountTypeSelector(),
                    SizedBox(height: 24),
                      Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ??
                            Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha((0.1 * 255).round()),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'اسم الحساب',
                              prefixIcon: Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.grey.withAlpha(
                                    (0.3 * 255).round(),
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.grey.withAlpha(
                                    (0.3 * 255).round(),
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                              ),
                              filled: true,
                              fillColor: Colors.grey.withAlpha(
                                (0.05 * 255).round(),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'اسم الحساب مطلوب';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _initialBalanceController,
                            decoration: InputDecoration(
                              labelText: 'الرصيد الأولي',
                              prefixIcon: Icon(
                                Icons.attach_money,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                              ),
                              filled: true,
                              fillColor: Colors.grey.withAlpha(
                                (0.05 * 255).round(),
                              ),
                            ),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  double.tryParse(value) == null) {
                                return 'الرجاء إدخال رقم صحيح للرصيد الأولي';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            decoration: InputDecoration(
                              labelText: 'العملة',
                              prefixIcon: Icon(
                                Icons.currency_exchange,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.grey.withAlpha(
                                    (0.3 * 255).round(),
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                              ),
                              filled: true,
                              fillColor: Colors.grey.withAlpha(
                                (0.05 * 255).round(),
                              ),
                            ),
                            items:
                                availableCurrencies.map((String currency) {
                                  return DropdownMenuItem<String>(
                                    value: currency,
                                    child: Text(currency),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCurrency = newValue;
                                });
                              }
                            },
                            validator:
                                (value) =>
                                    value == null ? 'العملة مطلوبة' : null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Consumer<AccountProvider>(
                      builder: (context, accountProvider, child) {
                        return ElevatedButton(
                          onPressed:
                              accountProvider.isLoading ? null : _saveAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 2,
                          ),
                          child:
                              accountProvider.isLoading
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'حفظ الحساب',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                        );
                      },
                    ),
                    if (Provider.of<AccountProvider>(context).errorMessage !=
                        null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).expenseColor.withAlpha((0.1 * 255).round()),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Theme.of(context).expenseColor),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  Provider.of<AccountProvider>(
                                    context,
                                  ).errorMessage!,
                                  style: TextStyle(color: Theme.of(context).expenseColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
