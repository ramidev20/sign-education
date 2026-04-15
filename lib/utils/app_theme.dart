import 'package:flutter/material.dart';

class AppTheme {
  /// ===== FIGMA-DERIVED DOMINANT PALETTE =====
  /// Derived from the UI kit thumbnail node `219:68`.
  static const Color brand = Color(0xFF907CFF); // Primary violet
  static const Color accent = Color(0xFF947EFB); // Accent violet (selection)

  static const Color success = Color(0xFF027A48);
  static const Color successContainer = Color(0xFFECFDF3);

  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const Color background = Color(0xFFF0F2F8);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF475467);
  static const Color outline = Color(0xFFD0D5DD);

  static const Duration animationDuration = Duration(milliseconds: 400);
  static const Curve animationCurve = Curves.easeInOutCubic;

  // Shared Border Radius
  static const BorderRadius globalRadius = BorderRadius.all(
    Radius.circular(16),
  );

  static const BorderRadius smallRadius = BorderRadius.all(
    Radius.circular(12),
  );

  /// ===== LIGHT THEME =====
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: brand,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFECE9FF),
      onPrimaryContainer: Color(0xFF1F144D),

      secondary: accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF1EDFF),
      onSecondaryContainer: Color(0xFF22115A),

      tertiary: success,
      onTertiary: Colors.white,
      tertiaryContainer: successContainer,
      onTertiaryContainer: Color(0xFF053321),

      error: error,
      onError: Colors.white,

      background: background,
      onBackground: textPrimary,

      surface: surface,
      onSurface: textPrimary,
      surfaceVariant: Color(0xFFF2F4F7),
      onSurfaceVariant: textSecondary,

      outline: outline,
      outlineVariant: Color(0xFFE4E7EC),
      shadow: Color(0xFF0B1220),
    ),
    scaffoldBackgroundColor: background,

    // ===== AppBar =====
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),

    // ===== Text =====
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
      labelLarge: TextStyle(fontWeight: FontWeight.w600),
    ),

    iconTheme: const IconThemeData(color: textPrimary),

    // ===== Cards =====
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: globalRadius),
      shadowColor: Color(0xFF0B1220),
      surfaceTintColor: Colors.transparent,
    ),

    // ===== Buttons =====
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: brand,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: globalRadius),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: globalRadius),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brand,
        side: const BorderSide(color: outline, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: globalRadius),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brand,
        shape: const RoundedRectangleBorder(borderRadius: smallRadius),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // ===== Inputs =====
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: const OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: BorderSide(color: brand, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: BorderSide(color: error, width: 1.6),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: BorderSide(color: error, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
    ),

    dropdownMenuTheme: const DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: globalRadius,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: globalRadius,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: globalRadius,
          borderSide: BorderSide(color: brand, width: 2),
        ),
      ),
    ),

    // ===== Selection Controls =====
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(borderRadius: smallRadius),
      side: const BorderSide(color: outline),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? brand
            : Colors.transparent,
      ),
      checkColor: WidgetStateProperty.all(Colors.white),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? brand
            : const Color(0xFF667085),
      ),
    ),

    // ===== Navigation Bar =====
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: brand.withOpacity(0.1),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? brand
              : const Color(0xFF667085),
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: brand,
      unselectedItemColor: Color(0xFF667085),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: brand,
      unselectedLabelColor: textSecondary,
      indicatorColor: brand,
      dividerColor: outline,
    ),

    // ===== FAB =====
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: brand,
      foregroundColor: Colors.white,
    ),

    // ===== Switch / Slider =====
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? brand
            : const Color(0xFFE4E7EC),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? brand.withOpacity(0.35)
            : const Color(0xFFD0D5DD),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: brand,
      thumbColor: brand,
      inactiveTrackColor: brand.withOpacity(0.2),
      overlayColor: brand.withOpacity(0.1),
    ),

    // ===== Divider =====
    dividerTheme: const DividerThemeData(
      color: outline,
      thickness: 1,
    ),

    // ===== Chip =====
    chipTheme: ChipThemeData(
      backgroundColor: brand.withOpacity(0.1),
      labelStyle: const TextStyle(color: textPrimary),
      selectedColor: brand,
      shape: RoundedRectangleBorder(borderRadius: globalRadius),
      side: BorderSide(color: brand.withOpacity(0.3)),
    ),

    // ===== Dialog / Sheets / Menus =====
    dialogTheme: const DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: globalRadius),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(color: textSecondary, fontSize: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: globalRadius),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: textPrimary,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: const RoundedRectangleBorder(borderRadius: globalRadius),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: textSecondary,
      textColor: textPrimary,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: brand,
      linearTrackColor: Color(0xFFE4E7EC),
    ),
  );

  /// ===== DARK THEME =====
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: brand,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF2B1F5C),
      onPrimaryContainer: Color(0xFFECE9FF),

      secondary: accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF251759),
      onSecondaryContainer: Color(0xFFF1EDFF),

      tertiary: success,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF06402A),
      onTertiaryContainer: Color(0xFFB7E6D0),

      error: error,
      onError: Colors.white,

      background: Color(0xFF0B1220),
      onBackground: Color(0xFFF9FAFB),

      surface: Color(0xFF111827),
      onSurface: Color(0xFFF9FAFB),
      surfaceVariant: Color(0xFF1F2937),
      onSurfaceVariant: Color(0xFFCBD5E1),

      outline: Color(0xFF475569),
      outlineVariant: Color(0xFF334155),
      shadow: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFF0B1220),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111827),
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
    cardTheme: const CardThemeData(
      color: Color(0xFF111E2E),
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: globalRadius),
      shadowColor: Colors.black,
      surfaceTintColor: Colors.transparent,
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

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: globalRadius),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Color(0xFF475569), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: globalRadius),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0F1B2A),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: const OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: BorderSide(color: Color(0xFF475569)),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: BorderSide(color: Color(0xFF475569)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: BorderSide(color: brand, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: BorderSide(color: error, width: 1.6),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: globalRadius,
        borderSide: BorderSide(color: error, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: brand,
      foregroundColor: Colors.white,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF111827),
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
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF111827),
      selectedItemColor: brand,
      unselectedItemColor: Color(0xFFCBD5E1),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: brand,
      unselectedLabelColor: Color(0xFFCBD5E1),
      indicatorColor: brand,
      dividerColor: Color(0xFF334155),
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

    dropdownMenuTheme: const DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF0F1B2A),
        border: OutlineInputBorder(
          borderRadius: globalRadius,
          borderSide: BorderSide(color: Color(0xFF475569)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: globalRadius,
          borderSide: BorderSide(color: Color(0xFF475569)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: globalRadius,
          borderSide: BorderSide(color: brand, width: 2),
        ),
      ),
    ),

    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(borderRadius: smallRadius),
      side: const BorderSide(color: Color(0xFF475569)),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? brand
            : Colors.transparent,
      ),
      checkColor: WidgetStateProperty.all(Colors.white),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? brand
            : const Color(0xFF94A3B8),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? brand
            : const Color(0xFFCBD5E1),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? brand.withOpacity(0.35)
            : const Color(0xFF334155),
      ),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF111827),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: globalRadius),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(color: Colors.white70, fontSize: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF111827),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Color(0xFF111827),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: globalRadius),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xFF0B1220),
      contentTextStyle: TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: globalRadius),
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
