import 'package:flutter/services.dart';

class BiometricService {
  // Mock implementation for biometric authentication
  // This will be replaced with actual local_auth implementation when the package is installed

  // Check if biometric authentication is available
  Future<bool> isAvailable() async {
    try {
      // Mock implementation - always return false for now
      return false;
    } on PlatformException catch (e) {
      print('Error checking biometrics availability: $e');
      return false;
    }
  }

  // Get available biometric types
  Future<List<String>> getAvailableBiometrics() async {
    try {
      // Mock implementation - return empty list
      return [];
    } on PlatformException catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Authenticate user with biometrics
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      // Mock implementation - always return false for now
      return false;
    } on PlatformException catch (e) {
      print('Error during biometric authentication: $e');
      return false;
    }
  }

  // Get biometric type description
  String getBiometricTypeDescription(String type) {
    switch (type.toLowerCase()) {
      case 'fingerprint':
        return 'بصمة الإصبع';
      case 'face':
        return 'التعرف على الوجه';
      case 'iris':
        return 'قزحية العين';
      case 'voice':
        return 'التعرف على الصوت';
      default:
        return 'المصادقة البيومترية';
    }
  }

  // Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      // Mock implementation - always return false for now
      return false;
    } on PlatformException catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  // Get authentication error message
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'NotAvailable':
        return 'المصادقة البيومترية غير متاحة على هذا الجهاز';
      case 'NotEnrolled':
        return 'لم يتم تسجيل أي بصمة حيوية على هذا الجهاز';
      case 'LockedOut':
        return 'تم قفل المصادقة البيومترية مؤقتاً';
      case 'PermanentlyLockedOut':
        return 'تم قفل المصادقة البيومترية نهائياً';
      case 'UserCancel':
        return 'تم إلغاء المصادقة من قبل المستخدم';
      case 'AuthenticationFailed':
        return 'فشل في المصادقة البيومترية';
      default:
        return 'حدث خطأ في المصادقة البيومترية';
    }
  }
}
