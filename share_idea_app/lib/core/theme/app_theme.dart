import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? AppColors.volcanic950 : AppColors.cream;
    final surface = isDark ? AppColors.labPanel : AppColors.surface;
    final card = isDark ? AppColors.labPanelRaised : AppColors.surfaceRaised;
    final border = isDark ? AppColors.labLine : AppColors.line;
    final text = isDark ? Colors.white : AppColors.ink;
    final subtext =
        isDark ? Colors.white.withValues(alpha: 0.46) : AppColors.graphite;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.ochre : AppColors.green,
      onPrimary: isDark ? AppColors.volcanic950 : Colors.white,
      secondary: isDark ? AppColors.patinaTeal : AppColors.teal,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: text,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Inter',

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.transparent : bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: isDark ? 0 : 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
                .copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark
                .copyWith(statusBarColor: Colors.transparent),
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          fontFamily: 'SpaceGrotesk',
        ),
      ),

      // Light: white card with soft shadow. Dark: dark card with border.
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 0 : 1,
        shadowColor:
            isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDark ? 6 : 10),
          side: isDark ? BorderSide(color: border, width: 1) : BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.black.withValues(alpha: 0.22)
            : AppColors.lightSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDark ? 6 : 10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDark ? 6 : 10),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDark ? 6 : 10),
          borderSide: BorderSide(
            color: isDark ? AppColors.ochre : AppColors.green,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDark ? 6 : 12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: TextStyle(color: subtext, fontSize: 14),
        labelStyle: TextStyle(color: subtext),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.ochre : AppColors.green,
          foregroundColor: isDark ? AppColors.volcanic950 : Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFamily: 'SpaceGrotesk',
            letterSpacing: 1.8,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.ochre : AppColors.greenDark,
          side: BorderSide(color: isDark ? AppColors.ochre : AppColors.green),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFamily: 'SpaceGrotesk',
            letterSpacing: 1.6,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.ochre : AppColors.greenDark,
          textStyle:
              const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
        ),
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      chipTheme: ChipThemeData(
        backgroundColor: card,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: text, fontSize: 12, fontFamily: 'Inter'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
            color: text,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: 0),
        displayMedium: TextStyle(
            color: text,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2),
        headlineLarge:
            TextStyle(color: text, fontSize: 26, fontWeight: FontWeight.w700),
        headlineMedium:
            TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w700),
        headlineSmall:
            TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge:
            TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w700),
        titleMedium:
            TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w600),
        titleSmall:
            TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: text, fontSize: 16, height: 1.6),
        bodyMedium: TextStyle(color: text, fontSize: 14, height: 1.6),
        bodySmall: TextStyle(color: subtext, fontSize: 12, height: 1.5),
        labelLarge:
            TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: subtext, fontSize: 11),
      ),
    );
  }
}
