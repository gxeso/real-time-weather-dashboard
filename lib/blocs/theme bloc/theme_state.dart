import 'package:flutter/material.dart';

class ThemeState {
  const ThemeState({required this.themeMode});

  const ThemeState.dark() : themeMode = ThemeMode.dark;

  final ThemeMode themeMode;

  bool get isDarkMode => themeMode == ThemeMode.dark;
}
