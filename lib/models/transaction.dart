enum TransactionType { expense, income, transfer }

class Transaction {
  final String? id;
  final String accountId;
  final String categoryId;
  final double amount;
  final TransactionType type;
  final String? description;
  final DateTime transactionDate;
  final String? userId;
  final String status;
  final String? toAccountId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? metadata;
  final bool isRecurring;
  final String? recurringRuleId;

  Transaction({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    this.description,
    DateTime? transactionDate,
    required this.userId,
    this.status = 'completed',
    this.toAccountId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.metadata,
    this.isRecurring = false,
    this.recurringRuleId,
  }) : transactionDate = transactionDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // تحويل من Firestore
  factory Transaction.fromFirestore(Map<String, dynamic> data, String docId) {
    return Transaction(
      id: docId,
      accountId: data['accountId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => TransactionType.expense,
      ),
      description: data['description'],
      transactionDate: DateTime.parse(data['transactionDate']),
      userId: data['userId'],
      status: data['status'] ?? 'completed',
      toAccountId: data['toAccountId'],
      createdAt: DateTime.parse(
        data['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        data['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      metadata: data['metadata'],
      isRecurring: data['isRecurring'] ?? false,
      recurringRuleId: data['recurringRuleId'],
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'type': type.toString(),
      'description': description,
      'transactionDate': transactionDate.toIso8601String(),
      'userId': userId,
      'status': status,
      'toAccountId': toAccountId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'isRecurring': isRecurring,
      'recurringRuleId': recurringRuleId,
    };
  }

  // نسخة مع التعديلات
  Transaction copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    double? amount,
    TransactionType? type,
    String? description,
    DateTime? transactionDate,
    String? userId,
    String? status,
    String? toAccountId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? metadata,
    bool? isRecurring,
    String? recurringRuleId,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      toAccountId: toAccountId ?? this.toAccountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
    );
  }

  // Convert Transaction object to a Map object for database operations
  Map<String, dynamic> toMap() {
    final map = {
      'amount': amount,
      'type': type.toString().split('.').last,
      'categoryId': categoryId,
      'accountId': accountId,
      'description': description,
      'transactionDate': transactionDate.toIso8601String(),
      'userId': userId,
      'status': status,
      'toAccountId': toAccountId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'isRecurring': isRecurring ? 1 : 0,
      'recurringRuleId': recurringRuleId,
    };

    // أضف المعرف فقط إذا كان موجوداً (للتحديث)
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  // Create Transaction object from a Map object from database
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'] as String,
      ),
      categoryId: map['categoryId'] as String,
      accountId: map['accountId'] as String,
      description: map['description'] as String?,
      transactionDate: DateTime.parse(map['transactionDate'] as String),
      userId: map['userId'] as String?,
      status: map['status'] as String? ?? 'completed',
      toAccountId: map['toAccountId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      metadata: map['metadata'] as String?,
      isRecurring: (map['isRecurring'] as int?) == 1,
      recurringRuleId: map['recurringRuleId'] as String?,
    );
  }

  // Keep the existing fromJson and toJson methods for API operations but update types
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
      ),
      categoryId: json['categoryId'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      description: json['description'] as String?,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      userId: json['userId'] as String?,
      status: json['status'] as String? ?? 'completed',
      toAccountId: json['toAccountId'] as String?,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      metadata: json['metadata'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringRuleId: json['recurringRuleId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type.toString().split('.').last,
      'categoryId': categoryId,
      'accountId': accountId,
      'description': description,
      'userId': userId,
      'status': status,
      'toAccountId': toAccountId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'isRecurring': isRecurring,
      'recurringRuleId': recurringRuleId,
    };
  }

  @override
  String toString() {
    return 'Transaction{id: $id, amount: $amount, type: $type, categoryId: $categoryId, accountId: $accountId, description: $description, transactionDate: $transactionDate}';
  }
}
