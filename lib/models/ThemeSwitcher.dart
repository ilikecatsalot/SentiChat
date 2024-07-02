import 'package:flutter/material.dart';

class ThemeSwitcher extends StatelessWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const ThemeSwitcher({
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: isDarkMode,
      onChanged: onThemeChanged,
    );
  }
}