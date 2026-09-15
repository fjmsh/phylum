import 'package:flutter/material.dart';

const seedColor = Color(0xff769e57);

sealed class PhylumTheme {
  static final _light = _generateAppTheme(Brightness.light);
  static ThemeData get light => _light;

  static final _dark = _generateAppTheme(Brightness.dark);
  static ThemeData get dark => _dark;

  const PhylumTheme._();
}

ThemeData _generateAppTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    brightness: brightness,
  );
  final border = const BorderRadius.all(Radius.circular(8.0));
  return ThemeData(
    colorScheme: colorScheme,
    brightness: brightness,
    inputDecorationTheme: InputDecorationThemeData(
      border: OutlineInputBorder(borderRadius: border),
      enabledBorder: OutlineInputBorder(
        borderRadius: border,
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: border,
        borderSide: BorderSide(color: colorScheme.primary, width: 1.0),
      ),
    ),
  );
}
