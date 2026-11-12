import 'package:material_ui/material_ui.dart';

/// Identidade visual: verde-escuro #3D5C40 e verde-sálvia #A8B08C.
/// Botões grandes e alto contraste para uso no campo (luvas, sol forte).
class AppColors {
  static const primary = Color(0xFF3D5C40);
  static const secondary = Color(0xFFA8B08C);
  static const background = Color(0xFFF6F7F2);
  static const warning = Color(0xFFB26A00);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  var scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  );
  scheme = dark
      ? scheme.copyWith(primary: const Color(0xFF9CC5A0), secondary: AppColors.secondary)
      : scheme.copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.secondary,
          onSecondary: const Color(0xFF1D241E),
          surface: AppColors.background,
        );

  const minButton = Size(64, 56);
  const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: dark ? null : AppColors.background,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? null : AppColors.primary,
      foregroundColor: dark ? null : Colors.white,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: minButton, textStyle: buttonText, shape: shape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minButton,
        textStyle: buttonText,
        shape: shape,
        side: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), textStyle: buttonText),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      extendedTextStyle: buttonText,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: dark ? null : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      color: dark ? null : Colors.white,
      margin: EdgeInsets.zero,
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      indicatorColor: AppColors.secondary.withValues(alpha: dark ? 0.35 : 0.6),
    ),
  );
}
