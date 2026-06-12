// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StickyNotesApp());
}

class StickyNotesApp extends StatefulWidget {
  const StickyNotesApp({super.key});

  @override
  State<StickyNotesApp> createState() => _StickyNotesAppState();
}

class _StickyNotesAppState extends State<StickyNotesApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  bool get _isDark {
    if (_themeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // ── Material 3 colour seeds ──────────────────────────────────────────────

  static const _seed = Color(0xFFFBC02D); // warm amber seed

  static final _lightScheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.light,
  );

  static final _darkScheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.dark,
  );

  ThemeData _buildTheme(ColorScheme cs) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: cs.surfaceTint,
        titleTextStyle: TextStyle(
          color: cs.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.primaryContainer;
          }
          return null;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sticky Notes',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(_lightScheme),
      darkTheme: _buildTheme(_darkScheme),
      home: HomeScreen(
        onToggleTheme: _toggleTheme,
        isDark: _isDark,
      ),
    );
  }
}