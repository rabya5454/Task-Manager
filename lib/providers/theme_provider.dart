import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme mode notifier - Synchronous with background loading
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _key = 'theme_mode';

  @override
  ThemeMode build() {
    // Start with system theme, then load saved preference
    _loadThemeMode();
    return ThemeMode.system;
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_key);

      if (savedMode != null) {
        final mode = ThemeMode.values.firstWhere(
              (m) => m.toString() == savedMode,
          orElse: () => ThemeMode.system,
        );
        state = mode;
      }
    } catch (e) {
      // If loading fails, keep system theme
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.toString());
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
      () => ThemeModeNotifier(),
);

// Remember me notifier - Synchronous with background loading
class RememberMeNotifier extends Notifier<bool> {
  static const String _key = 'remember_me';
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';

  @override
  bool build() {
    _loadRememberMe();
    return false;
  }

  Future<void> _loadRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? false;
    } catch (e) {
      debugPrint('Error loading remember me: $e');
    }
  }

  Future<void> setRememberMe(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (e) {
      debugPrint('Error saving remember me: $e');
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emailKey, email);
      await prefs.setString(_passwordKey, password);
      await prefs.setBool(_key, true);
      state = true;
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  Future<Map<String, String>?> getCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_key) ?? false;

      if (!rememberMe) return null;

      final email = prefs.getString(_emailKey);
      final password = prefs.getString(_passwordKey);

      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
    } catch (e) {
      debugPrint('Error getting credentials: $e');
    }
    return null;
  }

  Future<void> clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emailKey);
      await prefs.remove(_passwordKey);
      await prefs.setBool(_key, false);
      state = false;
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
    }
  }
}

final rememberMeProvider = NotifierProvider<RememberMeNotifier, bool>(
      () => RememberMeNotifier(),
);