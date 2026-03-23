import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart';

void main() {
  runApp(const TetBudgetApp());
}

class TetBudgetApp extends StatelessWidget {
  const TetBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFC62828);
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    final baseTextTheme = ThemeData.light().textTheme;
    final appTextTheme = GoogleFonts.beVietnamProTextTheme(baseTextTheme)
        .copyWith(
          displaySmall: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          headlineSmall: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          titleLarge: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
          titleMedium: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
          bodyMedium: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w500),
        );

    return MaterialApp(
      title: 'Săn Sale Tết',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme.copyWith(
          primary: const Color(0xFFC62828),
          secondary: const Color(0xFFF1A208),
          surface: const Color(0xFFFFFBF6),
          surfaceContainerHighest: const Color(0xFFF9EADB),
        ),
        textTheme: appTextTheme,
        scaffoldBackgroundColor: const Color(0xFFFFF8F2),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF3C1F1B),
          titleTextStyle: appTextTheme.headlineSmall?.copyWith(
            color: const Color(0xFF3C1F1B),
            fontSize: 26,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.26),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.primary, width: 1.6),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        chipTheme: ChipThemeData(
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          selectedColor: const Color(0xFFFFE6CF),
          backgroundColor: Colors.white,
          labelStyle: appTextTheme.labelLarge,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC62828),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: appTextTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFC62828),
          foregroundColor: Colors.white,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
