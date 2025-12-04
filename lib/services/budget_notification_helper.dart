import '../services/notification_service.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class BudgetNotificationHelper {
  static final NotificationService _notificationService = NotificationService();

  // Check budget limits and send alerts
  static Future<void> checkBudgetLimits({
    required List<Category> categories,
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    for (final category in categories) {
      if (category.budgetLimit == null || category.budgetLimit! <= 0) continue;

      // Calculate spent amount for this category in the period
      final spentAmount = _calculateSpentAmount(
        transactions: transactions,
        categoryId: category.id!,
        startDate: startDate,
        endDate: endDate,
      );

      // Check if budget limit is exceeded
      if (spentAmount >= category.budgetLimit!) {
        await _notificationService.scheduleNotification(
          1,
          'تجاوز الميزانية',
          'لقد تجاوزت ميزانية ${category.name}',
          DateTime.now().add(const Duration(minutes: 1)),
          'budget_exceeded_${category.id}',
        );
      }
      // Check if approaching budget limit (80% threshold)
      else if (spentAmount >= category.budgetLimit! * 0.8) {
        await _notificationService.scheduleNotification(
          2,
          'اقتراب من الميزانية',
          'أنت تقترب من تجاوز ميزانية ${category.name}',
          DateTime.now().add(const Duration(minutes: 1)),
          'budget_warning_${category.id}',
        );
      }
    }
  }

  // Calculate spent amount for a category in a given period
  static double _calculateSpentAmount({
    required List<Transaction> transactions,
    required String categoryId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return transactions
        .where(
          (transaction) =>
              transaction.categoryId == categoryId &&
              transaction.type == TransactionType.expense &&
              transaction.transactionDate.isAfter(startDate) &&
              transaction.transactionDate.isBefore(endDate),
        )
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Schedule monthly budget review reminder
  static Future<void> scheduleMonthlyBudgetReview() async {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    await _notificationService.scheduleNotification(
      'monthly_budget_review'.hashCode,
      'مراجعة الميزانية الشهرية',
      'حان وقت مراجعة ميزانيتك الشهرية وتحديد الميزانيات الجديدة',
      nextMonth,
      'monthly_budget_review',
    );
  }

  // Schedule weekly spending review
  static Future<void> scheduleWeeklySpendingReview() async {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    await _notificationService.scheduleNotification(
      'weekly_spending_review'.hashCode,
      'مراجعة المصروفات الأسبوعية',
      'راجع مصروفاتك الأسبوعية وتأكد من عدم تجاوز الميزانيات',
      nextWeek,
      'weekly_spending_review',
    );
  }

  // Schedule budget setup reminder for new users
  static Future<void> scheduleBudgetSetupReminder() async {
    await _notificationService.scheduleNotification(
      'budget_setup_reminder'.hashCode,
      'إعداد الميزانيات',
      'قم بإعداد ميزانياتك الشهرية لتحكم أفضل في مصروفاتك',
      DateTime.now().add(const Duration(hours: 24)),
      'budget_setup_reminder',
    );
  }

  // Check and alert for overspending patterns
  static Future<void> checkOverspendingPatterns({
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Calculate daily average spending
    final days = endDate.difference(startDate).inDays + 1;
    final totalSpent = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final dailyAverage = totalSpent / days;

    // Alert if daily average is too high (more than 200 SAR per day)
    if (dailyAverage > 200) {
      await _notificationService.scheduleNotification(
        'overspending_alert'.hashCode,
        'تحذير من الإفراط في الإنفاق',
        'متوسط إنفاقك اليومي ${dailyAverage.toStringAsFixed(2)} ريال. حاول تقليل المصروفات غير الضرورية',
        DateTime.now().add(const Duration(minutes: 1)),
        'overspending_alert',
      );
    }
  }

  // Schedule category-specific spending alerts
  static Future<void> scheduleCategoryAlerts({
    required List<Category> categories,
    required List<Transaction> transactions,
  }) async {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 0);

    for (final category in categories) {
      if (category.budgetLimit == null) continue;

      final spentAmount = _calculateSpentAmount(
        transactions: transactions,
        categoryId: category.id!,
        startDate: thisMonthStart,
        endDate: thisMonthEnd,
      );

      // Schedule mid-month check
      final midMonth = DateTime(now.year, now.month, 15);
      if (now.day < 15 && spentAmount > category.budgetLimit! * 0.5) {
        await _notificationService.scheduleNotification(
          'mid_month_${category.id}'.hashCode,
          'تحذير منتصف الشهر - ${category.name}',
          'لقد أنفقت ${spentAmount.toStringAsFixed(2)} ريال من ميزانية ${category.name} في النصف الأول من الشهر',
          midMonth,
          'mid_month_alert:${category.id}',
        );
      }
    }
  }
}
