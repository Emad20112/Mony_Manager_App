import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:mony_manager/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService with ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // تشفير كلمة المرور باستخدام SHA-256
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // تدفق حالة المستخدم
  Stream<UserModel?> get userStream {
    return _auth.authStateChanges().map((firebase_auth.User? user) {
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    });
  }

  // الحصول على المستخدم الحالي
  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user != null ? UserModel.fromFirebaseUser(user) : null;
  }

  // تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final firebase_auth.UserCredential result = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return UserModel.fromFirebaseUser(result.user!);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // إنشاء حساب جديد بالبريد الإلكتروني وكلمة المرور
  Future<UserModel> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final firebase_auth.UserCredential result = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return UserModel.fromFirebaseUser(result.user!);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // تسجيل الدخول باستخدام Google
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw 'تم إلغاء تسجيل الدخول بواسطة المستخدم';

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth
          .GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential result = await _auth
          .signInWithCredential(credential);
      return UserModel.fromFirebaseUser(result.user!);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // تسجيل الدخول باستخدام Facebook
  Future<UserModel> signInWithFacebook() async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();
      if (loginResult.status != LoginStatus.success) {
        throw 'فشل تسجيل الدخول باستخدام Facebook';
      }

      final firebase_auth.OAuthCredential credential = firebase_auth
          .FacebookAuthProvider.credential(loginResult.accessToken!.token);

      final firebase_auth.UserCredential result = await _auth
          .signInWithCredential(credential);
      return UserModel.fromFirebaseUser(result.user!);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // تسجيل الدخول برقم الهاتف
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(UserModel) onVerified,
    required Function(String) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (
          firebase_auth.PhoneAuthCredential credential,
        ) async {
          final firebase_auth.UserCredential result = await _auth
              .signInWithCredential(credential);
          onVerified(UserModel.fromFirebaseUser(result.user!));
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          onError(_handleAuthException(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(_handleAuthException(e));
    }
  }

  // التحقق من رمز الهاتف
  Future<UserModel> verifyPhoneCode(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final firebase_auth.PhoneAuthCredential credential = firebase_auth
          .PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final firebase_auth.UserCredential result = await _auth
          .signInWithCredential(credential);
      return UserModel.fromFirebaseUser(result.user!);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // إرسال رابط إعادة تعيين كلمة المرور
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // تحديث معلومات المستخدم
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // تغيير كلمة المرور
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) throw 'لم يتم تسجيل الدخول';

      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // معالجة أخطاء المصادقة
  String _handleAuthException(dynamic e) {
    if (e is firebase_auth.FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'لم يتم العثور على حساب بهذا البريد الإلكتروني';
        case 'wrong-password':
          return 'كلمة المرور غير صحيحة';
        case 'email-already-in-use':
          return 'البريد الإلكتروني مستخدم بالفعل';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صالح';
        case 'weak-password':
          return 'كلمة المرور ضعيفة جداً';
        case 'operation-not-allowed':
          return 'هذه العملية غير مسموح بها';
        case 'invalid-verification-code':
          return 'رمز التحقق غير صالح';
        case 'invalid-verification-id':
          return 'معرف التحقق غير صالح';
        default:
          return 'حدث خطأ غير متوقع: ${e.message}';
      }
    }
    return 'حدث خطأ غير متوقع: $e';
  }
}
