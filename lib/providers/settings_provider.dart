import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';

class SettingsProvider with ChangeNotifier {
  final SharedPreferences? _prefs;
  bool _isLoading = false;
  String? _error;

  // Settings
  String _language = 'ar';
  String _currency = 'SAR';
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _budgetAlertsEnabled = true;
  bool _biometricEnabled = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get language => _language;
  String get currency => _currency;
  bool get darkMode => _darkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get budgetAlertsEnabled => _budgetAlertsEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool _biometricAvailable = false;
  bool get biometricAvailable => _biometricAvailable;

  SettingsProvider({SharedPreferences? prefs}) : _prefs = prefs {
    initSettings();
  }

  Future<void> initSettings() async {
    try {
      _isLoading = true;
      notifyListeners();

      _language = _prefs?.getString('language') ?? 'ar';
      _currency = _prefs?.getString('currency') ?? 'SAR';
      _darkMode = _prefs?.getBool('darkMode') ?? false;
      _notificationsEnabled = _prefs?.getBool('notifications') ?? true;
      _budgetAlertsEnabled = _prefs?.getBool('budgetAlerts') ?? true;
      _biometricEnabled = _prefs?.getBool('biometric') ?? false;

      // Check biometric availability
      final biometricService = BiometricService();
      _biometricAvailable = await biometricService.isAvailable();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String lang) async {
    try {
      await _prefs?.setString('language', lang);
      _language = lang;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setCurrency(String curr) async {
    try {
      await _prefs?.setString('currency', curr);
      _currency = curr;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    try {
      await _prefs?.setBool('darkMode', value);
      _darkMode = value;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleNotifications(bool value) async {
    try {
      await _prefs?.setBool('notifications', value);
      _notificationsEnabled = value;

      // Update notification service
      final notificationService = NotificationService();
      notificationService.setNotificationsEnabled(value);

      if (value) {
        // Schedule notifications when enabled
        await notificationService.scheduleAllNotifications();
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleBudgetAlerts(bool value) async {
    try {
      await _prefs?.setBool('budgetAlerts', value);
      _budgetAlertsEnabled = value;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> toggleBiometric(bool value) async {
    try {
      if (value) {
        // If enabling biometric, authenticate first
        final biometricService = BiometricService();
        final authenticated = await biometricService.authenticate(
          localizedReason: 'يرجى التحقق من هويتك لتفعيل المصادقة البيومترية',
        );

        if (!authenticated) {
          return false;
        }
      }

      await _prefs?.setBool('biometric', value);
      _biometricEnabled = value;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> backupData() async {
    // Navigate to backup screen
    // This is handled in the UI layer
  }

  Future<void> restoreData() async {
    // Navigate to backup screen
    // This is handled in the UI layer
  }

  Future<void> clearAllData() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _prefs?.clear();
      await initSettings(); // Reset to defaults

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
