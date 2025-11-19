import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  Locale _locale = const Locale('pt', 'BR');
  ThemeMode _themeMode = ThemeMode.system;
  bool _privacyMode = false;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get privacyMode => _privacyMode;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void togglePrivacyMode(bool value) {
    if (_privacyMode == value) return;
    _privacyMode = value;
    notifyListeners();
  }
}
