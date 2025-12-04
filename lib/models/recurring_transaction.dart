enum RecurringFrequency { daily, weekly, monthly, yearly, custom }

enum RecurringStatus { active, paused, completed, cancelled }

class RecurringTransaction {
  final String? id;
  final String accountId;
  final String categoryId;
  final double amount;
  final String description;
  final RecurringFrequency frequency;
  final int interval; // Every X days/weeks/months/years
  final DateTime startDate;
  final DateTime? endDate;
  final int? maxOccurrences;
  final RecurringStatus status;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastExecuted;
  final int executedCount;
  final Map<String, dynamic>? metadata;

  RecurringTransaction({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.frequency,
    this.interval = 1,
    required this.startDate,
    this.endDate,
    this.maxOccurrences,
    this.status = RecurringStatus.active,
    required this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastExecuted,
    this.executedCount = 0,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    final map = {
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'frequency': frequency.name,
      'interval': interval,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'status': status.name,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastExecuted': lastExecuted?.toIso8601String(),
      'executedCount': executedCount,
      'metadata': metadata != null ? metadata.toString() : null,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  // Create from Map
  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] as String?,
      accountId: map['accountId'] as String,
      categoryId: map['categoryId'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      interval: map['interval'] as int? ?? 1,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate:
          map['endDate'] != null
              ? DateTime.parse(map['endDate'] as String)
              : null,
      maxOccurrences: map['maxOccurrences'] as int?,
      status: RecurringStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RecurringStatus.active,
      ),
      userId: map['userId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      lastExecuted:
          map['lastExecuted'] != null
              ? DateTime.parse(map['lastExecuted'] as String)
              : null,
      executedCount: map['executedCount'] as int? ?? 0,
      metadata:
          map['metadata'] != null
              ? Map<String, dynamic>.from(map['metadata'])
              : null,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'frequency': frequency.name,
      'interval': interval,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'status': status.name,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastExecuted': lastExecuted?.toIso8601String(),
      'executedCount': executedCount,
      'metadata': metadata,
    };
  }

  // Create from Firestore
  factory RecurringTransaction.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return RecurringTransaction(
      id: docId,
      accountId: data['accountId'] as String,
      categoryId: data['categoryId'] as String,
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] as String,
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == data['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      interval: data['interval'] as int? ?? 1,
      startDate: DateTime.parse(data['startDate'] as String),
      endDate:
          data['endDate'] != null
              ? DateTime.parse(data['endDate'] as String)
              : null,
      maxOccurrences: data['maxOccurrences'] as int?,
      status: RecurringStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RecurringStatus.active,
      ),
      userId: data['userId'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      lastExecuted:
          data['lastExecuted'] != null
              ? DateTime.parse(data['lastExecuted'] as String)
              : null,
      executedCount: data['executedCount'] as int? ?? 0,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Copy with modifications
  RecurringTransaction copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    double? amount,
    String? description,
    RecurringFrequency? frequency,
    int? interval,
    DateTime? startDate,
    DateTime? endDate,
    int? maxOccurrences,
    RecurringStatus? status,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastExecuted,
    int? executedCount,
    Map<String, dynamic>? metadata,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      executedCount: executedCount ?? this.executedCount,
      metadata: metadata ?? this.metadata,
    );
  }

  // Calculate next execution date
  DateTime? getNextExecutionDate() {
    if (status != RecurringStatus.active) return null;
    if (maxOccurrences != null && executedCount >= maxOccurrences!) return null;
    if (endDate != null && DateTime.now().isAfter(endDate!)) return null;

    DateTime nextDate = lastExecuted ?? startDate;

    switch (frequency) {
      case RecurringFrequency.daily:
        nextDate = nextDate.add(Duration(days: interval));
        break;
      case RecurringFrequency.weekly:
        nextDate = nextDate.add(Duration(days: interval * 7));
        break;
      case RecurringFrequency.monthly:
        nextDate = DateTime(
          nextDate.year,
          nextDate.month + interval,
          nextDate.day,
        );
        break;
      case RecurringFrequency.yearly:
        nextDate = DateTime(
          nextDate.year + interval,
          nextDate.month,
          nextDate.day,
        );
        break;
      case RecurringFrequency.custom:
        // For custom frequency, use interval as days
        nextDate = nextDate.add(Duration(days: interval));
        break;
    }

    // Check if next date is within end date
    if (endDate != null && nextDate.isAfter(endDate!)) return null;

    return nextDate;
  }

  // Check if should execute now
  bool shouldExecuteNow() {
    final nextDate = getNextExecutionDate();
    if (nextDate == null) return false;

    return DateTime.now().isAfter(nextDate) ||
        DateTime.now().isAtSameMomentAs(nextDate);
  }

  // Get frequency description in Arabic
  String getFrequencyDescription() {
    switch (frequency) {
      case RecurringFrequency.daily:
        return interval == 1 ? 'يومياً' : 'كل $interval أيام';
      case RecurringFrequency.weekly:
        return interval == 1 ? 'أسبوعياً' : 'كل $interval أسابيع';
      case RecurringFrequency.monthly:
        return interval == 1 ? 'شهرياً' : 'كل $interval أشهر';
      case RecurringFrequency.yearly:
        return interval == 1 ? 'سنوياً' : 'كل $interval سنوات';
      case RecurringFrequency.custom:
        return 'كل $interval أيام';
    }
  }

  // Get status description in Arabic
  String getStatusDescription() {
    switch (status) {
      case RecurringStatus.active:
        return 'نشط';
      case RecurringStatus.paused:
        return 'معلق';
      case RecurringStatus.completed:
        return 'مكتمل';
      case RecurringStatus.cancelled:
        return 'ملغي';
    }
  }

  @override
  String toString() {
    return 'RecurringTransaction{id: $id, description: $description, amount: $amount, frequency: $frequency, status: $status}';
  }
}
