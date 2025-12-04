import 'package:uuid/uuid.dart';

class Wish {
  final String id;
  final String title;
  final double targetAmount;
  double savedAmount;
  final DateTime createdAt;

  Wish({
    String? id,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0.0,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  double get progressPercentage => (savedAmount / targetAmount) * 100;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Wish.fromJson(Map<String, dynamic> json) {
    return Wish(
      id: json['id'],
      title: json['title'],
      targetAmount: json['targetAmount'],
      savedAmount: json['savedAmount'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
