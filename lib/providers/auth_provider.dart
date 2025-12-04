// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'firestore_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    // الاستماع لتغييرات حالة المصادقة
    _authService.userStream.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<void> _initializeUserData(
    String userId,
    FirestoreProvider firestoreProvider,
  ) async {
    try {
      await firestoreProvider.initializeUserData(userId);
    } catch (e) {
      _setError('فشل في تهيئة بيانات المستخدم: $e');
    }
  }

  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
    FirestoreProvider firestoreProvider,
  ) async {
    _setLoading(true);
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      _currentUser = user;
      await _initializeUserData(user.uid, firestoreProvider);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
    FirestoreProvider firestoreProvider,
  ) async {
    _setLoading(true);
    try {
      final user = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );
      _currentUser = user;
      await _initializeUserData(user.uid, firestoreProvider);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle(FirestoreProvider firestoreProvider) async {
    _setLoading(true);
    try {
      final user = await _authService.signInWithGoogle();
      _currentUser = user;
      await _initializeUserData(user.uid, firestoreProvider);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithFacebook(FirestoreProvider firestoreProvider) async {
    _setLoading(true);
    try {
      final user = await _authService.signInWithFacebook();
      _currentUser = user;
      await _initializeUserData(user.uid, firestoreProvider);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(UserModel) onVerified,
    required Function(String) onError,
    required FirestoreProvider firestoreProvider,
  }) async {
    _setLoading(true);
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onVerified: (user) async {
          _currentUser = user;
          await _initializeUserData(user.uid, firestoreProvider);
          onVerified(user);
        },
        onError: onError,
      );
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyPhoneCode(
    String verificationId,
    String smsCode,
    FirestoreProvider firestoreProvider,
  ) async {
    _setLoading(true);
    try {
      final user = await _authService.verifyPhoneCode(verificationId, smsCode);
      _currentUser = user;
      await _initializeUserData(user.uid, firestoreProvider);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    _setLoading(true);
    try {
      await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setLoading(true);
    try {
      await _authService.updatePassword(currentPassword, newPassword);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
