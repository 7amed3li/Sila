import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class AppFonts {
  static TextStyle cairo({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return _copyWithParams(
      const TextStyle(fontFamily: 'Cairo'),
      textStyle, color, backgroundColor, fontSize, fontWeight, fontStyle,
      letterSpacing, wordSpacing, textBaseline, height, locale, foreground,
      background, shadows, fontFeatures, decoration, decorationColor,
      decorationStyle, decorationThickness,
    );
  }

  static TextStyle outfit({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return _copyWithParams(
      const TextStyle(fontFamily: 'Outfit'),
      textStyle, color, backgroundColor, fontSize, fontWeight, fontStyle,
      letterSpacing, wordSpacing, textBaseline, height, locale, foreground,
      background, shadows, fontFeatures, decoration, decorationColor,
      decorationStyle, decorationThickness,
    );
  }

  static TextTheme outfitTextTheme([TextTheme? base]) {
    base ??= ThemeData.light().textTheme;
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: 'Outfit'),
      displayMedium: base.displayMedium?.copyWith(fontFamily: 'Outfit'),
      displaySmall: base.displaySmall?.copyWith(fontFamily: 'Outfit'),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: 'Outfit'),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'Outfit'),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'Outfit'),
      titleLarge: base.titleLarge?.copyWith(fontFamily: 'Outfit'),
      titleMedium: base.titleMedium?.copyWith(fontFamily: 'Outfit'),
      titleSmall: base.titleSmall?.copyWith(fontFamily: 'Outfit'),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Outfit'),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Outfit'),
      bodySmall: base.bodySmall?.copyWith(fontFamily: 'Outfit'),
      labelLarge: base.labelLarge?.copyWith(fontFamily: 'Outfit'),
      labelMedium: base.labelMedium?.copyWith(fontFamily: 'Outfit'),
      labelSmall: base.labelSmall?.copyWith(fontFamily: 'Outfit'),
    );
  }

  static TextStyle amiri({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return _copyWithParams(
      const TextStyle(fontFamily: 'Amiri'),
      textStyle, color, backgroundColor, fontSize, fontWeight, fontStyle,
      letterSpacing, wordSpacing, textBaseline, height, locale, foreground,
      background, shadows, fontFeatures, decoration, decorationColor,
      decorationStyle, decorationThickness,
    );
  }

  static TextStyle scheherazadeNew({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return _copyWithParams(
      const TextStyle(fontFamily: 'ScheherazadeNew'),
      textStyle, color, backgroundColor, fontSize, fontWeight, fontStyle,
      letterSpacing, wordSpacing, textBaseline, height, locale, foreground,
      background, shadows, fontFeatures, decoration, decorationColor,
      decorationStyle, decorationThickness,
    );
  }

  static TextStyle notoNaskhArabic({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return _copyWithParams(
      const TextStyle(fontFamily: 'NotoNaskhArabic'),
      textStyle, color, backgroundColor, fontSize, fontWeight, fontStyle,
      letterSpacing, wordSpacing, textBaseline, height, locale, foreground,
      background, shadows, fontFeatures, decoration, decorationColor,
      decorationStyle, decorationThickness,
    );
  }

  static TextStyle notoKufiArabic({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return _copyWithParams(
      const TextStyle(fontFamily: 'NotoKufiArabic'),
      textStyle, color, backgroundColor, fontSize, fontWeight, fontStyle,
      letterSpacing, wordSpacing, textBaseline, height, locale, foreground,
      background, shadows, fontFeatures, decoration, decorationColor,
      decorationStyle, decorationThickness,
    );
  }

  static TextStyle getFont(
    String fontName, {
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    const supportedFonts = [
      'Cairo', 'Outfit', 'Amiri', 'ScheherazadeNew', 
      'NotoNaskhArabic', 'NotoKufiArabic', 'KFGQPCUthmanicScript'
    ];
    if (!supportedFonts.contains(fontName)) {
      fontName = 'Cairo'; // Fallback للمستخدمين القدامى أو القيم غير المعروفة
    }
    return _copyWithParams(
      TextStyle(fontFamily: fontName),
      textStyle, color, backgroundColor, fontSize, fontWeight, fontStyle,
      letterSpacing, wordSpacing, textBaseline, height, locale, foreground,
      background, shadows, fontFeatures, decoration, decorationColor,
      decorationStyle, decorationThickness,
    );
  }

  static TextStyle _copyWithParams(
    TextStyle base,
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  ) {
    var merged = textStyle == null ? base : base.merge(textStyle);
    return merged.copyWith(
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }
}
