import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/wish.dart';

class WishesProvider with ChangeNotifier {
  List<Wish> _wishes = [];
  final String _storageKey = 'wishes';

  List<Wish> get wishes => [..._wishes];

  WishesProvider() {
    _loadWishes();
  }

  Future<void> _loadWishes() async {
    final prefs = await SharedPreferences.getInstance();
    final wishesJson = prefs.getString(_storageKey);
    if (wishesJson != null) {
      final List<dynamic> decodedList = json.decode(wishesJson);
      _wishes = decodedList.map((item) => Wish.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveWishes() async {
    final prefs = await SharedPreferences.getInstance();
    final wishesJson = json.encode(_wishes.map((w) => w.toJson()).toList());
    await prefs.setString(_storageKey, wishesJson);
  }

  Future<void> addWish(String title, double targetAmount) async {
    final wish = Wish(title: title, targetAmount: targetAmount);
    _wishes.add(wish);
    await _saveWishes();
    notifyListeners();
  }

  Future<void> addAmountToWish(String wishId, double amount) async {
    final wishIndex = _wishes.indexWhere((w) => w.id == wishId);
    if (wishIndex != -1) {
      _wishes[wishIndex].savedAmount += amount;
      await _saveWishes();
      notifyListeners();
    }
  }

  Future<void> deleteWish(String wishId) async {
    _wishes.removeWhere((w) => w.id == wishId);
    await _saveWishes();
    notifyListeners();
  }
}
