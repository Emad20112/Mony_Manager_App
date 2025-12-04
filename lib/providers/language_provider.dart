import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('ar', ''); // Default to Arabic
  bool _isInitialized = false;

  Locale get currentLocale => _currentLocale;
  bool get isInitialized => _isInitialized;

  // Get current language code
  String get currentLanguageCode => _currentLocale.languageCode;

  // Check if current language is Arabic
  bool get isArabic => _currentLocale.languageCode == 'ar';

  // Check if current language is English
  bool get isEnglish => _currentLocale.languageCode == 'en';

  // Initialize language from preferences
  Future<void> initializeLanguage() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'ar';
      _currentLocale = Locale(languageCode, '');
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // If there's an error, use default language
      _currentLocale = const Locale('ar', '');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == _currentLocale.languageCode) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);

      _currentLocale = Locale(languageCode, '');
      notifyListeners();
    } catch (e) {
      // Handle error silently or show a message
      debugPrint('Error changing language: $e');
    }
  }

  // Toggle between Arabic and English
  Future<void> toggleLanguage() async {
    final newLanguageCode = _currentLocale.languageCode == 'ar' ? 'en' : 'ar';
    await changeLanguage(newLanguageCode);
  }

  // Get available languages
  List<Map<String, String>> get availableLanguages => [
    {'code': 'ar', 'name': 'العربية', 'nativeName': 'العربية'},
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
  ];

  // Get language name by code
  String getLanguageName(String languageCode) {
    final language = availableLanguages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse:
          () => {
            'code': languageCode,
            'name': languageCode,
            'nativeName': languageCode,
          },
    );
    return language['nativeName']!;
  }

  // Get current language name
  String get currentLanguageName =>
      getLanguageName(_currentLocale.languageCode);
}
