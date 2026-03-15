import 'package:flutter/material.dart';

class AppTheme {
  /// ===== GLOBAL BRAND COLOR =====
  /// Change this once and the whole app adapts (like Duolingo green or purple).
  static const Color brand = Color(0xFF7C3AED); // Purple
  static const Color accent = Color(0xFF06B6D4); // Cyan
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const Duration animationDuration = Duration(milliseconds: 400);
  static const Curve animationCurve = Curves.easeInOutCubic;

  // Shared Border Radius
  static const BorderRadius globalRadius = BorderRadius.all(
    Radius.circular(16),
  );

  /// ===== LIGHT THEME =====
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: brand,
      secondary: accent,
      tertiary: success,
      error: error,
      surface: Colors.white,
      background: Color(0xFFF8FAFC),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),

    // ===== AppBar =====
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFF111827),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: Color(0xFF111827)),
    ),

    // ===== Text =====
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF111827)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF374151)),
      labelLarge: TextStyle(fontWeight: FontWeight.w600),
    ),

    // ===== Cards =====
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: globalRadius),
      shadowColor: brand,
    ),

    // ===== Buttons =====
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        backgroundColor: brand,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: globalRadius),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: globalRadius),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brand,
        side: const BorderSide(color: brand, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: globalRadius),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // ===== Inputs =====
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: BorderSide(color: brand, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF374151)),
    ),

    // ===== Navigation Bar =====
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: brand.withOpacity(0.1),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? brand
              : const Color(0xFF6B7280),
        ),
      ),
    ),

    // ===== FAB =====
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: brand,
      foregroundColor: Colors.white,
    ),

    // ===== Switch / Slider =====
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(brand),
      trackColor: WidgetStateProperty.all(brand.withOpacity(0.3)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: brand,
      thumbColor: brand,
      inactiveTrackColor: brand.withOpacity(0.2),
      overlayColor: brand.withOpacity(0.1),
    ),

    // ===== Divider =====
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE5E7EB),
      thickness: 1,
    ),

    // ===== Chip =====
    chipTheme: ChipThemeData(
      backgroundColor: brand.withOpacity(0.1),
      labelStyle: const TextStyle(color: Color(0xFF111827)),
      selectedColor: brand,
      shape: RoundedRectangleBorder(borderRadius: globalRadius),
      side: BorderSide(color: brand.withOpacity(0.3)),
    ),
  );

  /// ===== DARK THEME =====
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: brand,
      secondary: accent,
      tertiary: success,
      error: error,
      surface: Color(0xFF1E293B),
      background: Color(0xFF0F172A),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white60),
    ),

    // ===== Cards =====
    cardTheme: CardThemeData(
      color: Color(0xFF253141),
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: globalRadius),
      shadowColor: Colors.black45,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: globalRadius),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: BorderSide(color: brand.withOpacity(0.7), width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: globalRadius),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF334155),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: BorderSide(color: brand, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: brand,
      foregroundColor: Colors.white,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1E293B),
      indicatorColor: brand.withOpacity(0.25),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? brand : Colors.white70,
        ),
      ),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, color: Colors.white70),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: brand.withOpacity(0.25),
      labelStyle: const TextStyle(color: Colors.white),
      selectedColor: brand,
      shape: RoundedRectangleBorder(borderRadius: globalRadius),
      side: BorderSide(color: brand.withOpacity(0.3)),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFF334155),
      thickness: 1,
    ),
  );

  /// ===== ANIMATED WRAPPER =====
  static Widget animated({required bool darkMode, required Widget child}) {
    return AnimatedTheme(
      data: darkMode ? AppTheme.dark : AppTheme.light,
      duration: animationDuration,
      curve: animationCurve,
      child: AnimatedSwitcher(
        duration: animationDuration,
        switchInCurve: animationCurve,
        switchOutCurve: animationCurve,
        child: child,
      ),
    );
  }
}
