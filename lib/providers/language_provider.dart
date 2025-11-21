import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'selected_language';

  // Supported locales
  static const Locale _defaultLocale = Locale('en');
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('vi'), // Vietnamese
  ];

  Locale _currentLocale = _defaultLocale;
  bool _isLoading = false;

  Locale get currentLocale => _currentLocale;
  bool get isLoading => _isLoading;

  // Initialize and load saved language preference
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadSavedLanguage();
    } catch (e) {
      debugPrint('Error loading language preference: $e');
      // Keep default language if loading fails
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);

      if (languageCode != null) {
        final savedLocale = Locale(languageCode);

        // Validate that the saved language is supported
        if (supportedLocales.contains(savedLocale)) {
          _currentLocale = savedLocale;
        }
      }
    } catch (e) {
      debugPrint('Error loading saved language: $e');
      // Keep default locale if loading fails
    }
  }

  // Save language to SharedPreferences
  Future<void> _saveLanguage(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
    } catch (e) {
      debugPrint('Error saving language: $e');
      throw Exception('Failed to save language preference');
    }
  }

  // Change the current language
  Future<void> changeLanguage(Locale newLocale) async {
    try {
      // Validate that the new language is supported
      if (!supportedLocales.contains(newLocale)) {
        throw Exception('Unsupported language: ${newLocale.languageCode}');
      }

      _currentLocale = newLocale;
      await _saveLanguage(newLocale);
      notifyListeners();
    } catch (e) {
      debugPrint('Error changing language: $e');
      throw Exception('Failed to change language');
    }
  }

  // Get language name for display
  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'vi':
        return 'Tiếng Việt';
      default:
        return locale.languageCode.toUpperCase();
    }
  }

  // Get current language display name
  String get currentLanguageName => getLanguageName(_currentLocale);

  // Check if a locale is currently selected
  bool isCurrentLanguage(Locale locale) {
    return _currentLocale == locale;
  }

  // Reset to default language
  Future<void> resetToDefault() async {
    await changeLanguage(_defaultLocale);
  }

  // Get locale from language code string
  static Locale? getLocaleFromCode(String languageCode) {
    try {
      final locale = Locale(languageCode);
      return supportedLocales.contains(locale) ? locale : null;
    } catch (e) {
      return null;
    }
  }

  // Get system locale if supported, otherwise return default
  static Locale getSystemLocaleOrDefault() {
    try {
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final matchingLocale = supportedLocales.firstWhere(
        (locale) => locale.languageCode == systemLocale.languageCode,
        orElse: () => _defaultLocale,
      );
      return matchingLocale;
    } catch (e) {
      return _defaultLocale;
    }
  }
}