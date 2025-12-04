import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import '../utils/theme_extensions.dart'; // لألوان التصميم

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = 'expense';
  IconData _selectedIcon = Icons.shopping_bag;

  // استخدام الألوان من الثيم بدلاً من الألوان الثابتة

  // قائمة الأيقونات المتاحة
  final List<IconData> _availableIcons = [
    Icons.shopping_bag,
    Icons.fastfood,
    Icons.local_grocery_store,
    Icons.directions_car,
    Icons.home,
    Icons.medical_services,
    Icons.school,
    Icons.sports_esports,
    Icons.airplane_ticket,
    Icons.attach_money,
    Icons.account_balance,
    Icons.credit_card,
    Icons.savings,
    Icons.work,
    Icons.card_giftcard,
    Icons.favorite,
    Icons.fitness_center,
    Icons.pets,
    Icons.local_hospital,
    Icons.phone_android,
  ];

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      try {
        final categoryProvider = Provider.of<CategoryProvider>(
          context,
          listen: false,
        );

        final newCategory = Category(
          name: _nameController.text.trim(),
          type: _selectedType,
          icon: _selectedIcon.codePoint.toString(),
          userId: 'default_user', // إضافة userId مطلوب
        );

        await categoryProvider.addCategory(newCategory);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إضافة الفئة بنجاح'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Theme.of(context).expenseColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة فئة جديدة'), elevation: 0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(
                context,
              ).colorScheme.primary.withAlpha((0.1 * 255).round()),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // اسم الفئة
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الفئة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha((0.5 * 255).round()),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha((0.5 * 255).round()),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.category,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال اسم الفئة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // نوع الفئة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).inputDecorationTheme.fillColor ??
                        Theme.of(context).cardTheme.color ??
                        Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha((0.5 * 255).round()),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: 'expense',
                          child: Row(
                            children: [
                              Icon(
                                Icons.money_off,
                                color: Theme.of(context).expenseColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'مصروفات',
                                style: TextStyle(
                                  color: Theme.of(context).expenseColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'income',
                          child: Row(
                            children: [
                              Icon(
                                Icons.money,
                                color: Theme.of(context).incomeColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'إيرادات',
                                style: TextStyle(
                                  color: Theme.of(context).incomeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedType = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // عنوان قسم الأيقونات
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'اختر أيقونة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // شبكة الأيقونات
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected = icon == _selectedIcon;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIcon = icon;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Theme.of(context).colorScheme.primary
                                      .withAlpha((0.2 * 255).round())
                                  : Theme.of(context).cardTheme.color ??
                                      Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              isSelected
                                  ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  )
                                  : Border.all(
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey.withAlpha(
                                              (0.3 * 255).round(),
                                            )
                                            : Colors.grey.withAlpha(
                                              (0.2 * 255).round(),
                                            ),
                                  ),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withAlpha((0.2 * 255).round()),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Icon(
                          icon,
                          color:
                              isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.color
                                          ?.withOpacity(0.7) ??
                                      Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // زر الحفظ
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    return ElevatedButton(
                      onPressed:
                          categoryProvider.isLoading ? null : _saveCategory,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child:
                          categoryProvider.isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'حفظ الفئة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
