class Category {
  final String? id;
  final String name;
  final String type; // "Income" or "Expense"
  final String? icon;
  final String? parentId;
  final int colorValue;
  final String? userId;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? budgetLimit;

  Category({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.parentId,
    this.colorValue = 0xFF6B8E23,
    required this.userId,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.budgetLimit,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert Category object to a Map object for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'icon': icon,
      'colorValue': colorValue,
      'userId': userId,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'parentId': parentId,
      'budgetLimit': budgetLimit,
    };
  }

  // Create Category object from a Firestore document
  factory Category.fromFirestore(Map<String, dynamic> data, String docId) {
    return Category(
      id: docId,
      name: data['name'] as String,
      type: data['type'] as String,
      icon: data['icon'] as String?,
      colorValue:
          data['colorValue'] != null
              ? int.tryParse(data['colorValue'].toString()) ?? 0xFF6B8E23
              : 0xFF6B8E23,
      userId: data['userId'] as String?,
      isDefault: data['isDefault'] ?? false,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      parentId: data['parentId'] as String?,
      budgetLimit: data['budgetLimit']?.toDouble(),
    );
  }

  // Convert Category object to a Map object for local database
  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'type': type,
      'icon': icon,
      'colorValue': colorValue,
      'userId': userId,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'parentId': parentId,
      'budgetLimit': budgetLimit,
    };

    // أضف المعرف فقط إذا كان موجوداً (للتحديث)
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  // Create Category object from a local database Map object
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String?,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String?,
      colorValue:
          map['colorValue'] is int
              ? map['colorValue'] as int
              : (map['colorValue'] != null
                  ? int.tryParse(map['colorValue'].toString()) ?? 0xFF6B8E23
                  : 0xFF6B8E23),
      userId: map['userId'] as String?,
      isDefault: (map['isDefault'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      parentId: map['parentId'] as String?,
      budgetLimit: map['budgetLimit']?.toDouble(),
    );
  }

  // نسخة مع التعديلات
  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? icon,
    String? parentId,
    int? colorValue,
    String? userId,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? budgetLimit,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      colorValue: colorValue ?? this.colorValue,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      budgetLimit: budgetLimit ?? this.budgetLimit,
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, type: $type, icon: $icon, parentId: $parentId, createdAt: $createdAt}';
  }
}
