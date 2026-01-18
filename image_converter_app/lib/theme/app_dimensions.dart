import 'package:flutter/material.dart';

/// Định nghĩa tất cả spacing, sizes, radius được sử dụng trong app
class AppDimensions {
  AppDimensions._(); // Private constructor

  //SPACING

  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing14 = 14.0;
  static const double spacing15 = 15.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing30 = 30.0;
  static const double spacing40 = 40.0;

  //  PADDING

  static const EdgeInsets paddingAll4 = EdgeInsets.all(4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(8);
  static const EdgeInsets paddingAll10 = EdgeInsets.all(10);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(12);
  static const EdgeInsets paddingAll14 = EdgeInsets.all(14);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(24);

  static const EdgeInsets paddingH8 = EdgeInsets.symmetric(horizontal: 8);
  static const EdgeInsets paddingH16 = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets paddingH20 = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets paddingH24 = EdgeInsets.symmetric(horizontal: 24);

  static const EdgeInsets paddingV8 = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets paddingV10 = EdgeInsets.symmetric(vertical: 10);
  static const EdgeInsets paddingV12 = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets paddingV14 = EdgeInsets.symmetric(vertical: 14);
  static const EdgeInsets paddingV20 = EdgeInsets.symmetric(vertical: 20);

  static const EdgeInsets paddingH8V8 = EdgeInsets.symmetric(horizontal: 8, vertical: 8);
  static const EdgeInsets paddingH16V8 = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets paddingH16V12 = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const EdgeInsets paddingH16V14 = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const EdgeInsets paddingH12V6 = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static const EdgeInsets paddingH12V8 = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  static const EdgeInsets paddingH12V16 = EdgeInsets.symmetric(horizontal: 12, vertical: 16);
  static const EdgeInsets paddingH8V2 = EdgeInsets.symmetric(horizontal: 8, vertical: 2);

  // BORDER RADIUS

  static const double radius2 = 2.0;
  static const double radius6 = 6.0;
  static const double radius8 = 8.0;
  static const double radius10 = 10.0;
  static const double radius12 = 12.0;
  static const double radius15 = 15.0;
  static const double radius20 = 20.0;
  static const double radius25 = 25.0;

  static BorderRadius borderRadius2 = BorderRadius.circular(radius2);
  static BorderRadius borderRadius6 = BorderRadius.circular(radius6);
  static BorderRadius borderRadius8 = BorderRadius.circular(radius8);
  static BorderRadius borderRadius10 = BorderRadius.circular(radius10);
  static BorderRadius borderRadius12 = BorderRadius.circular(radius12);
  static BorderRadius borderRadius15 = BorderRadius.circular(radius15);
  static BorderRadius borderRadius20 = BorderRadius.circular(radius20);
  static BorderRadius borderRadius25 = BorderRadius.circular(radius25);

  // Top only radius
  static BorderRadius borderRadiusTop25 = const BorderRadius.vertical(top: Radius.circular(25));

  // Bottom only radius
  static BorderRadius borderRadiusBottom30 = const BorderRadius.vertical(bottom: Radius.circular(30));

  //   ICON SIZES

  static const double iconSizeSmall = 14.0;
  static const double iconSizeMedium = 16.0;
  static const double iconSizeRegular = 24.0;
  static const double iconSizeLarge = 30.0;
  static const double iconSizeXLarge = 32.0;
  static const double iconSizeXXLarge = 36.0;
  static const double iconSizeHuge = 50.0;
  static const double iconSizeMassive = 64.0;
  static const double iconSizeGiant = 80.0;

  //ELEVATION

  static const double elevation0 = 0;
  static const double elevation2 = 2;
  static const double elevation3 = 3;
  static const double elevation4 = 4;
  static const double elevation10 = 10;

  //COMPONENT SIZES

  static const double buttonHeightSmall = 50.0;
  static const double buttonHeightMedium = 55.0;
  static const double buttonHeightLarge = 56.0;

  static const double avatarSizeSmall = 40.0;
  static const double avatarSizeMedium = 50.0;
  static const double avatarSizeRegular = 70.0;
  static const double avatarSizeLarge = 80.0;
  static const double avatarSizeXLarge = 100.0;

  static const double appBarHeight = 70.0;

  static const double dragHandleWidth = 40.0;
  static const double dragHandleHeight = 4.0;

  static const double progressBarHeight = 10.0;

  //BORDER WIDTH

  static const double borderWidth1 = 1.0;
  static const double borderWidth2 = 2.0;

  //BLUR RADIUS

  static const double blurRadius8 = 8.0;
  static const double blurRadius10 = 10.0;
  static const double blurRadius15 = 15.0;
  static const double blurRadius20 = 20.0;

  //SLIDER

  static const double sliderThumbRadius = 10.0;
  static const double sliderOverlayRadius = 20.0;
  static const double sliderTrackHeight = 6.0;
}
