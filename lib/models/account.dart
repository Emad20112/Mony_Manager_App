class Account {
  final String? id;
  final String name;
  final double balance;
  final String currency;
  final String type;
  final int colorValue;
  final String? description;
  final String? userId;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? icon;

  Account({
    this.id,
    required this.name,
    required this.balance,
    this.currency = 'SAR',
    this.type = 'cash',
    this.colorValue = 0xFF6B8E23,
    this.description,
    required this.userId,
    this.isArchived = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.icon,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // تحويل من Firestore
  factory Account.fromFirestore(Map<String, dynamic> data, String docId) {
    return Account(
      id: docId,
      name: data['name'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'SAR',
      type: data['type'] ?? 'cash',
      colorValue:
          data['colorValue'] != null
              ? int.tryParse(data['colorValue'].toString()) ?? 0xFF6B8E23
              : 0xFF6B8E23,
      description: data['description'],
      userId: data['userId'],
      isArchived: data['isArchived'] ?? false,
      createdAt: DateTime.parse(
        data['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        data['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      icon: data['icon'],
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'balance': balance,
      'currency': currency,
      'type': type,
      'colorValue': colorValue,
      'description': description,
      'userId': userId,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'icon': icon,
    };
  }

  // نسخة مع التعديلات
  Account copyWith({
    String? id,
    String? name,
    double? balance,
    String? currency,
    String? type,
    int? colorValue,
    String? description,
    String? userId,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? icon,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      icon: icon ?? this.icon,
    );
  }

  // Convert Account object to a Map object for database insertion/update
  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'colorValue': colorValue,
      'description': description,
      'userId': userId,
      'isArchived': isArchived ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'icon': icon,
    };

    // أضف المعرف فقط إذا كان موجوداً (للتحديث)
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  // Create Account object from a Map object retrieved from database
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String?,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      currency: map['currency'] as String,
      type: map['type'] as String,
      colorValue:
          map['colorValue'] is int
              ? map['colorValue'] as int
              : (map['colorValue'] != null
                  ? int.tryParse(map['colorValue'].toString()) ?? 0xFF6B8E23
                  : 0xFF6B8E23),
      description: map['description'] as String?,
      userId: map['userId'] as String?,
      isArchived: (map['isArchived'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      icon: map['icon'] as String?,
    );
  }

  @override
  String toString() {
    return 'Account{id: $id, name: $name, type: $type, balance: $balance, currency: $currency}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
