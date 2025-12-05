import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mony_manager/models/goal.dart';
import 'package:mony_manager/providers/goal_provider.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ar',
    symbol: 'ر.س ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    // Load goals when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GoalProvider>(context, listen: false).loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأهداف المالية'), centerTitle: true),
      body: Consumer<GoalProvider>(
        builder: (context, goalProvider, child) {
          if (goalProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (goalProvider.goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد أهداف مالية حالياً',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أضف هدفاً مالياً جديداً للبدء في التخطيط لمستقبلك',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goalProvider.goals.length,
            itemBuilder: (context, index) {
              final goal = goalProvider.goals[index];
              final progress = goal.currentAmount / goal.targetAmount;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => _showGoalDetails(context, goal),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getGoalIcon(goal.category),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'تاريخ الإنجاز: ${DateFormat.yMMMd('ar').format(goal.targetDate)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showGoalOptions(context, goal),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Stack(
                          children: [
                            LinearProgressIndicator(
                              value: progress > 1.0 ? 1.0 : progress,
                              minHeight: 20,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            SizedBox(
                              height: 20,
                              child: Center(
                                child: Text(
                                  '${(progress * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _currencyFormat.format(goal.currentAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              _currencyFormat.format(goal.targetAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (goal.note.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            goal.note,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'goalsFAB',
        onPressed: () => _showAddGoalDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  IconData _getGoalIcon(String category) {
    switch (category.toLowerCase()) {
      case 'سفر':
        return Icons.flight;
      case 'تعليم':
        return Icons.school;
      case 'منزل':
        return Icons.home;
      case 'سيارة':
        return Icons.directions_car;
      case 'توفير':
        return Icons.savings;
      case 'استثمار':
        return Icons.trending_up;
      case 'زواج':
        return Icons.favorite;
      case 'تقاعد':
        return Icons.beach_access;
      default:
        return Icons.flag;
    }
  }

  void _showAddGoalDialog(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return const AddGoalForm();
      },
    );

    if (result == true) {
      // Goal was added, refresh the list
      Provider.of<GoalProvider>(context, listen: false).loadGoals();
    }
  }

  void _showGoalDetails(BuildContext context, Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return GoalDetailView(goal: goal);
      },
    );
  }

  void _showGoalOptions(BuildContext context, Goal goal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('تعديل الهدف'),
                onTap: () {
                  Navigator.pop(context);
                  _editGoal(context, goal);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('إضافة مبلغ'),
                onTap: () {
                  Navigator.pop(context);
                  _addContribution(context, goal);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'حذف الهدف',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteGoal(context, goal);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editGoal(BuildContext context, Goal goal) {
    // Show edit goal dialog/form
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return EditGoalForm(goal: goal);
      },
    );
  }

  void _addContribution(BuildContext context, Goal goal) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إضافة مبلغ للهدف',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (amountController.text.isNotEmpty) {
                      final amount = double.parse(amountController.text);
                      if (amount > 0) {
                        Provider.of<GoalProvider>(
                          context,
                          listen: false,
                        ).addContribution(goal.id, amount, noteController.text);
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('إضافة المبلغ'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteGoal(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('حذف الهدف'),
            content: Text('هل أنت متأكد من حذف الهدف "${goal.name}"؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Provider.of<GoalProvider>(
                    context,
                    listen: false,
                  ).deleteGoal(goal.id);
                },
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}

class AddGoalForm extends StatefulWidget {
  const AddGoalForm({super.key});

  @override
  State<AddGoalForm> createState() => _AddGoalFormState();
}

class _AddGoalFormState extends State<AddGoalForm> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final targetAmountController = TextEditingController();
  final currentAmountController = TextEditingController();
  final noteController = TextEditingController();

  String selectedCategory = 'توفير';
  DateTime targetDate = DateTime.now().add(const Duration(days: 365));

  final List<String> categories = [
    'توفير',
    'سفر',
    'تعليم',
    'منزل',
    'سيارة',
    'استثمار',
    'زواج',
    'تقاعد',
    'أخرى',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'إضافة هدف جديد',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الهدف',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال اسم الهدف';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'الفئة',
                border: OutlineInputBorder(),
              ),
              value: selectedCategory,
              items:
                  categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: targetAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ المستهدف',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال المبلغ المستهدف';
                }
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'الرجاء إدخال مبلغ صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: currentAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ الحالي (اختياري)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null ||
                      double.parse(value) < 0) {
                    return 'الرجاء إدخال مبلغ صحيح';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: targetDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );

                if (pickedDate != null) {
                  setState(() {
                    targetDate = pickedDate;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ الإنجاز',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat.yMMMd('ar').format(targetDate)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _saveGoal,
              child: const Text('حفظ الهدف'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _saveGoal() {
    if (formKey.currentState!.validate()) {
      final goal = Goal(
        id: '', // Will be generated by the provider
        name: nameController.text,
        category: selectedCategory,
        targetAmount: double.parse(targetAmountController.text),
        currentAmount:
            currentAmountController.text.isNotEmpty
                ? double.parse(currentAmountController.text)
                : 0,
        targetDate: targetDate,
        note: noteController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        contributions: [],
      );

      Provider.of<GoalProvider>(context, listen: false).addGoal(goal);
      Navigator.pop(context, true);
    }
  }
}

class EditGoalForm extends StatefulWidget {
  final Goal goal;

  const EditGoalForm({super.key, required this.goal});

  @override
  State<EditGoalForm> createState() => _EditGoalFormState();
}

class _EditGoalFormState extends State<EditGoalForm> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController targetAmountController;
  late final TextEditingController noteController;

  late String selectedCategory;
  late DateTime targetDate;

  final List<String> categories = [
    'توفير',
    'سفر',
    'تعليم',
    'منزل',
    'سيارة',
    'استثمار',
    'زواج',
    'تقاعد',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.goal.name);
    targetAmountController = TextEditingController(
      text: widget.goal.targetAmount.toString(),
    );
    noteController = TextEditingController(text: widget.goal.note);
    selectedCategory = widget.goal.category;
    targetDate = widget.goal.targetDate;
  }

  @override
  void dispose() {
    nameController.dispose();
    targetAmountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'تعديل الهدف',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الهدف',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال اسم الهدف';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'الفئة',
                border: OutlineInputBorder(),
              ),
              value: selectedCategory,
              items:
                  categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: targetAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ المستهدف',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال المبلغ المستهدف';
                }
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'الرجاء إدخال مبلغ صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: targetDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );

                if (pickedDate != null) {
                  setState(() {
                    targetDate = pickedDate;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ الإنجاز',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat.yMMMd('ar').format(targetDate)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _updateGoal,
              child: const Text('تحديث الهدف'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _updateGoal() {
    if (formKey.currentState!.validate()) {
      final updatedGoal = Goal(
        id: widget.goal.id,
        name: nameController.text,
        category: selectedCategory,
        targetAmount: double.parse(targetAmountController.text),
        currentAmount: widget.goal.currentAmount,
        targetDate: targetDate,
        note: noteController.text,
        createdAt: widget.goal.createdAt,
        updatedAt: DateTime.now(),
        contributions: widget.goal.contributions,
      );

      Provider.of<GoalProvider>(context, listen: false).updateGoal(updatedGoal);
      Navigator.pop(context, true);
    }
  }
}

class GoalDetailView extends StatelessWidget {
  final Goal goal;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ar',
    symbol: 'ر.س ',
    decimalDigits: 2,
  );

  GoalDetailView({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = goal.currentAmount / goal.targetAmount;
    final daysRemaining = goal.targetDate.difference(DateTime.now()).inDays;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getGoalIcon(goal.category),
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.category,
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              LinearProgressIndicator(
                value: progress > 1.0 ? 1.0 : progress,
                minHeight: 24,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              SizedBox(
                height: 24,
                child: Center(
                  child: Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailCard(context, 'الإحصائيات', [
            CardItem(
              'المبلغ الحالي',
              _currencyFormat.format(goal.currentAmount),
              Icons.account_balance_wallet,
            ),
            CardItem(
              'المبلغ المستهدف',
              _currencyFormat.format(goal.targetAmount),
              Icons.flag,
            ),
            CardItem(
              'المتبقي',
              _currencyFormat.format(goal.targetAmount - goal.currentAmount),
              Icons.hourglass_empty,
            ),
          ]),
          const SizedBox(height: 16),
          _buildDetailCard(context, 'التاريخ', [
            CardItem(
              'تاريخ البدء',
              DateFormat.yMMMd('ar').format(goal.createdAt),
              Icons.calendar_today,
            ),
            CardItem(
              'تاريخ الإنجاز',
              DateFormat.yMMMd('ar').format(goal.targetDate),
              Icons.event,
            ),
            CardItem('الأيام المتبقية', '$daysRemaining يوم', Icons.timer),
          ]),
          if (goal.contributions.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'المساهمات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: goal.contributions.length,
                itemBuilder: (context, index) {
                  final contribution = goal.contributions[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.add)),
                    title: Text(_currencyFormat.format(contribution.amount)),
                    subtitle: Text(
                      contribution.note.isNotEmpty
                          ? contribution.note
                          : DateFormat.yMMMd('ar').format(contribution.date),
                    ),
                    trailing: Text(
                      DateFormat.yMMMd('ar').format(contribution.date),
                    ),
                  );
                },
              ),
            ),
          ],
          if (goal.note.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'ملاحظات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(goal.note),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  IconData _getGoalIcon(String category) {
    switch (category.toLowerCase()) {
      case 'سفر':
        return Icons.flight;
      case 'تعليم':
        return Icons.school;
      case 'منزل':
        return Icons.home;
      case 'سيارة':
        return Icons.directions_car;
      case 'توفير':
        return Icons.savings;
      case 'استثمار':
        return Icons.trending_up;
      case 'زواج':
        return Icons.favorite;
      case 'تقاعد':
        return Icons.beach_access;
      default:
        return Icons.flag;
    }
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    List<CardItem> items,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }
}

class CardItem {
  final String label;
  final String value;
  final IconData icon;

  CardItem(this.label, this.value, this.icon);
}
