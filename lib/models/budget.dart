class Budget {
  final String? id;
  final String categoryId;
  final double amount;
  final String period; // e.g., "Monthly", "Yearly", "Weekly"
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  Budget({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Budget object to a Map object
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'amount': amount,
      'period': period,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create Budget object from a Map object
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String?,
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      period: map['period'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // نسخة مع التعديلات
  Budget copyWith({
    String? id,
    String? categoryId,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Budget{id: $id, categoryId: $categoryId, amount: $amount, period: $period, startDate: $startDate, endDate: $endDate, createdAt: $createdAt}';
  }
}
