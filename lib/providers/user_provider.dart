import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _repository;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserProvider(this._repository);

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> loadUser(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _repository.getUser(id);
      _error = _currentUser == null ? 'المستخدم غير موجود' : null;
    } catch (e) {
      _error = 'حدث خطأ أثناء تحميل بيانات المستخدم';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.insertUser(user);
      _currentUser = user;
    } catch (e) {
      _error = 'حدث خطأ أثناء إنشاء المستخدم';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateUser(user);
      _currentUser = user;
    } catch (e) {
      _error = 'حدث خطأ أثناء تحديث بيانات المستخدم';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    if (_currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateUserSettings(_currentUser!.id, settings);
      _currentUser = _currentUser!.copyWith(settings: settings);
    } catch (e) {
      _error = 'حدث خطأ أثناء تحديث إعدادات المستخدم';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
