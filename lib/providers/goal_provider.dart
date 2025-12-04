import 'package:flutter/material.dart';
import 'package:mony_manager/models/goal.dart';
import 'package:mony_manager/repositories/goal_repository.dart';

class GoalProvider extends ChangeNotifier {
  final GoalRepository _repository;
  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _error;

  GoalProvider(this._repository);

  // Getters
  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all goals from repository
  Future<void> loadGoals() async {
    _setLoading(true);
    try {
      _goals = await _repository.getGoals();
      _error = null;
    } catch (e) {
      _error = 'فشل تحميل الأهداف: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Add a new goal
  Future<void> addGoal(Goal goal) async {
    _setLoading(true);
    try {
      final newGoal = await _repository.addGoal(goal);
      _goals = [..._goals, newGoal];
      _error = null;
    } catch (e) {
      _error = 'فشل إضافة الهدف: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing goal
  Future<void> updateGoal(Goal updatedGoal) async {
    _setLoading(true);
    try {
      await _repository.updateGoal(updatedGoal);
      _goals =
          _goals.map((goal) {
            return goal.id == updatedGoal.id ? updatedGoal : goal;
          }).toList();
      _error = null;
    } catch (e) {
      _error = 'فشل تحديث الهدف: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Delete a goal
  Future<void> deleteGoal(String goalId) async {
    _setLoading(true);
    try {
      await _repository.deleteGoal(goalId);
      _goals = _goals.where((goal) => goal.id != goalId).toList();
      _error = null;
    } catch (e) {
      _error = 'فشل حذف الهدف: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Add a contribution to a goal
  Future<void> addContribution(
    String goalId,
    double amount,
    String note,
  ) async {
    _setLoading(true);
    try {
      final goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
      if (goalIndex == -1) {
        throw Exception('الهدف غير موجود');
      }

      final goal = _goals[goalIndex];
      final updatedGoal = goal.addContribution(amount, note);

      await _repository.updateGoal(updatedGoal);

      _goals =
          _goals.map((g) {
            return g.id == goalId ? updatedGoal : g;
          }).toList();

      _error = null;
    } catch (e) {
      _error = 'فشل إضافة مساهمة: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Get a specific goal by ID
  Goal? getGoalById(String goalId) {
    try {
      return _goals.firstWhere((goal) => goal.id == goalId);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
