import 'dart:convert';
import 'package:mony_manager/database/database_helper.dart';
import 'package:mony_manager/models/goal.dart';
import 'package:sqflite/sqflite.dart';

class GoalRepository {
  final DatabaseHelper _databaseHelper;
  final String _tableName = 'goals';

  GoalRepository(this._databaseHelper);

  // Get all goals from the database
  Future<List<Goal>> getGoals() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);

    return List.generate(maps.length, (i) {
      // Convert stringified JSON contributions back to objects
      final map = Map<String, dynamic>.from(maps[i]);
      if (map['contributions'] is String) {
        final List<dynamic> contributionsJson = jsonDecode(
          map['contributions'],
        );
        map['contributions'] = contributionsJson;
      } else {
        map['contributions'] = [];
      }

      return Goal.fromMap(map);
    });
  }

  // Add a new goal to the database
  Future<Goal> addGoal(Goal goal) async {
    final db = await _databaseHelper.database;

    // Convert contributions to JSON string for storage
    final Map<String, dynamic> goalMap = goal.toMap();
    goalMap['contributions'] = jsonEncode(goalMap['contributions']);

    final id = await db.insert(
      _tableName,
      goalMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // If the goal ID was generated in the database, update our model
    return goal.id.isEmpty ? goal.copyWith(id: id.toString()) : goal;
  }

  // Update an existing goal in the database
  Future<void> updateGoal(Goal goal) async {
    final db = await _databaseHelper.database;

    // Convert contributions to JSON string for storage
    final Map<String, dynamic> goalMap = goal.toMap();
    goalMap['contributions'] = jsonEncode(goalMap['contributions']);

    await db.update(_tableName, goalMap, where: 'id = ?', whereArgs: [goal.id]);
  }

  // Delete a goal from the database
  Future<void> deleteGoal(String goalId) async {
    final db = await _databaseHelper.database;

    await db.delete(_tableName, where: 'id = ?', whereArgs: [goalId]);
  }

  // Get a specific goal by ID
  Future<Goal?> getGoalById(String goalId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [goalId],
    );

    if (maps.isEmpty) {
      return null;
    }

    // Convert stringified JSON contributions back to objects
    final map = Map<String, dynamic>.from(maps.first);
    if (map['contributions'] is String) {
      final List<dynamic> contributionsJson = jsonDecode(map['contributions']);
      map['contributions'] = contributionsJson;
    } else {
      map['contributions'] = [];
    }

    return Goal.fromMap(map);
  }
}
