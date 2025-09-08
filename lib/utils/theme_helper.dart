import 'package:flutter/material.dart';

class ThemeHelper {
  static const Color _darkPrimaryColor = Color(0xFF7C3AED);
  static const Color _darkBackgroundStartColor = Color(0xFF1E293B);
  static const Color _darkBackgroundEndColor = Color(0xFF0F172A);
  static const Color _darkSidebarColor = Color(0xFF1E293B);
  static const Color _darkActiveNodeColor = Color(0xFF7C3AED);
  static const Color _darkInactiveNodeColor = Color(0xFF64748B);
  static const Color _darkConnectorColor = Color(0xFF7C3AED);
  static const Color _darkTextColor = Colors.white;
  static const Color _darkIconColor = Colors.white70;
  static const Color _darkBorderColor = Color(0xFF475569);
  static const Color _darkGridColor = Color(0xFF7C3AED);

  static const Color _lightPrimaryColor = Color(0xFF4F46E5);
  static const Color _lightBackgroundStartColor = Color(0xFFF8FAFC);
  static const Color _lightBackgroundEndColor = Color(0xFFE2E8F0);
  static const Color _lightSidebarColor = Color(0xFFFFFFFF);
  static const Color _lightActiveNodeColor = Color(0xFF4F46E5);
  static const Color _lightInactiveNodeColor = Color(0xFF94A3B8);
  static const Color _lightConnectorColor = Color(0xFF4F46E5);
  static const Color _lightTextColor = Color(0xFF1E293B);
  static const Color _lightIconColor = Color(0xFF64748B);
  static const Color _lightBorderColor = Color(0xFFE2E8F0);
  static const Color _lightGridColor = Color(0xFF4F46E5);

  static Color primaryColor(bool isDarkMode) => isDarkMode ? _darkPrimaryColor : _lightPrimaryColor;
  static Color backgroundStartColor(bool isDarkMode) => isDarkMode ? _darkBackgroundStartColor : _lightBackgroundStartColor;
  static Color backgroundEndColor(bool isDarkMode) => isDarkMode ? _darkBackgroundEndColor : _lightBackgroundEndColor;
  static Color sidebarColor(bool isDarkMode) => isDarkMode ? _darkSidebarColor : _lightSidebarColor;
  static Color activeNodeColor(bool isDarkMode) => isDarkMode ? _darkActiveNodeColor : _lightActiveNodeColor;
  static Color inactiveNodeColor(bool isDarkMode) => isDarkMode ? _darkInactiveNodeColor : _lightInactiveNodeColor;
  static Color connectorColor(bool isDarkMode) => isDarkMode ? _darkConnectorColor : _lightConnectorColor;
  static Color textColor(bool isDarkMode) => isDarkMode ? _darkTextColor : _lightTextColor;
  static Color iconColor(bool isDarkMode) => isDarkMode ? _darkIconColor : _lightIconColor;
  static Color borderColor(bool isDarkMode) => isDarkMode ? _darkBorderColor : _lightBorderColor;
  static Color gridColor(bool isDarkMode) => isDarkMode ? _darkGridColor : _lightGridColor;
}