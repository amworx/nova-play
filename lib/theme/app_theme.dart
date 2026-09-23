import 'package:flutter/material.dart';

/// Folio: Mono's bones warmed with Hearth's soul.
/// Paper background, ink text, sage signal, amber spark.
/// Chosen from the Dune mockup explorations.
class AppTheme {
  // Folio light
  static const bg = Color(0xFFF1EAD9);
  static const surface = Color(0xFFFBF7EC);
  static const ink = Color(0xFF23201A);
  static const accent = Color(0xFF7A8B6F); // sage
  static const accent2 = Color(0xFFE9B84C); // amber
  static const soft = Color(0xFFE3D7BE);
  // Folio dark
  static const bgDark = Color(0xFF16130E);
  static const surfaceDark = Color(0xFF201C15);
  static const inkDark = Color(0xFFF1EAD9);
  static const accentDark = Color(0xFF93A386);
  static const softDark = Color(0xFF2E2820);

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: accent,
      onPrimary: Colors.white,
      secondary: accent2,
      surface: surface,
      onSurface: ink,
      surfaceContainerHighest: soft,
      outlineVariant: soft,
    );
    return _base(scheme, Brightness.light);
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: accentDark,
      onPrimary: Color(0xFF16130E),
      secondary: accent2,
      surface: surfaceDark,
      onSurface: inkDark,
      surfaceContainerHighest: softDark,
      outlineVariant: softDark,
    );
    return _base(scheme, Brightness.dark);
  }

  static ThemeData _base(ColorScheme scheme, Brightness b) {
    final dark = b == Brightness.dark;
    final onSurface = scheme.onSurface;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? bgDark : bg,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        foregroundColor: onSurface,
        titleTextStyle: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? surfaceDark : surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.22),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: onSurface),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape:
            const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: scheme.primary,
        inactiveTrackColor: onSurface.withValues(alpha: 0.18),
        thumbColor: scheme.primary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor:
              dark ? const Color(0xFF16130E) : Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(linearMinHeight: 3),
    );
  }
}
