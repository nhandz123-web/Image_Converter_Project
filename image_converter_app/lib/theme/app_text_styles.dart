import 'package:flutter/material.dart';

/// Định nghĩa tất cả text styles được sử dụng trong app
class AppTextStyles {
  AppTextStyles._(); // Private constructor

  //FONT SIZES

  static const double fontSize9 = 9.0;
  static const double fontSize10 = 10.0;
  static const double fontSize11 = 11.0;
  static const double fontSize12 = 12.0;
  static const double fontSize13 = 13.0;
  static const double fontSize14 = 14.0;
  static const double fontSize15 = 15.0;
  static const double fontSize16 = 16.0;
  static const double fontSize18 = 18.0;
  static const double fontSize20 = 20.0;
  static const double fontSize22 = 22.0;
  static const double fontSize28 = 28.0;
  static const double fontSize32 = 32.0;

  // FONT WEIGHTS

  static const FontWeight weightNormal = FontWeight.normal;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.bold;

  // HEADINGS

  static const TextStyle h1 = TextStyle(
    fontSize: fontSize32,
    fontWeight: weightBold,
    letterSpacing: 1,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: fontSize22,
    fontWeight: weightBold,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: fontSize20,
    fontWeight: weightBold,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: fontSize18,
    fontWeight: weightBold,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: fontSize16,
    fontWeight: weightBold,
  );

  //BODY TEXT

  static const TextStyle bodyLarge = TextStyle(
    fontSize: fontSize16,
    fontWeight: weightNormal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: fontSize14,
    fontWeight: weightNormal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: fontSize12,
    fontWeight: weightNormal,
  );

  // BUTTON TEXT

  static const TextStyle button = TextStyle(
    fontSize: fontSize16,
    fontWeight: weightBold,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontSize: fontSize18,
    fontWeight: weightBold,
    letterSpacing: 0.5,
  );

  //LABELS & CAPTIONS

  static const TextStyle label = TextStyle(
    fontSize: fontSize13,
    fontWeight: weightMedium,
  );

  static const TextStyle caption = TextStyle(
    fontSize: fontSize11,
    fontWeight: weightNormal,
  );

  static const TextStyle captionSmall = TextStyle(
    fontSize: fontSize9,
  );

  //SPECIAL STYLES

  static const TextStyle subtitle = TextStyle(
    fontSize: fontSize14,
    fontWeight: weightMedium,
  );

  static const TextStyle subtitleBold = TextStyle(
    fontSize: fontSize15,
    fontWeight: weightSemiBold,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: fontSize15,
    fontWeight: weightSemiBold,
  );

  static const TextStyle listTitle = TextStyle(
    fontSize: fontSize15,
    fontWeight: weightSemiBold,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: fontSize12,
    fontWeight: weightSemiBold,
  );
}
