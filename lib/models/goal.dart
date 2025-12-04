import 'package:uuid/uuid.dart';

class Goal {
  final String id;
  final String name;
  final String category;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GoalContribution> contributions;

  Goal({
    required this.id,
    required this.name,
    required this.category,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.contributions,
  });

  factory Goal.create({
    required String name,
    required String category,
    required double targetAmount,
    double currentAmount = 0.0,
    required DateTime targetDate,
    String note = '',
  }) {
    final now = DateTime.now();
    return Goal(
      id: const Uuid().v4(),
      name: name,
      category: category,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: targetDate,
      note: note,
      createdAt: now,
      updatedAt: now,
      contributions: [],
    );
  }

  Goal copyWith({
    String? id,
    String? name,
    String? category,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<GoalContribution>? contributions,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contributions: contributions ?? this.contributions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.millisecondsSinceEpoch,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'contributions': contributions.map((e) => e.toMap()).toList(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      targetAmount: map['targetAmount'] as double,
      currentAmount: map['currentAmount'] as double,
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate'] as int),
      note: map['note'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      contributions:
          (map['contributions'] as List<dynamic>)
              .map((e) => GoalContribution.fromMap(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Goal addContribution(double amount, String note) {
    final now = DateTime.now();
    final contribution = GoalContribution(
      id: const Uuid().v4(),
      amount: amount,
      date: now,
      note: note,
    );

    final newContributions = [...contributions, contribution];
    final newCurrentAmount = currentAmount + amount;

    return copyWith(
      currentAmount: newCurrentAmount,
      updatedAt: now,
      contributions: newContributions,
    );
  }

  @override
  String toString() {
    return 'Goal(id: $id, name: $name, targetAmount: $targetAmount, currentAmount: $currentAmount)';
  }
}

class GoalContribution {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  GoalContribution({
    required this.id,
    required this.amount,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory GoalContribution.fromMap(Map<String, dynamic> map) {
    return GoalContribution(
      id: map['id'] as String,
      amount: map['amount'] as double,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: map['note'] as String,
    );
  }

  @override
  String toString() {
    return 'GoalContribution(id: $id, amount: $amount, date: $date)';
  }
}
