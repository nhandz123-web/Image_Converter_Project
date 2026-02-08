import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

/// Define common styles used across the app
class AppStyles {
  AppStyles._(); // Private constructor

  // ---------------------------------------------------------------------------
  // TEXT STYLES
  // ---------------------------------------------------------------------------

  static const TextStyle welcomeGreeting = TextStyle(
    color: AppColors.white,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle welcomeTitle = TextStyle(
    color: AppColors.white,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    height: 1.3,
    letterSpacing: -0.5,
    shadows: [
      Shadow(
        color: Colors.black26,
        offset: Offset(0, 2),
        blurRadius: 4,
      ),
    ],
  );

  static TextStyle viewAllLink(bool isDark, Color primaryColor) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.white : primaryColor,
    );
  }

  // ---------------------------------------------------------------------------
  // DECORATIONS
  // ---------------------------------------------------------------------------

  static BoxDecoration homeBackground(bool isDark) {
    return BoxDecoration(
      gradient: isDark
          ? AppColors.homeBackgroundGradientDark
          : AppColors.homeBackgroundGradientLight,
    );
  }

  static BoxDecoration welcomeCardBackground(bool isDark) {
    return BoxDecoration(
      gradient: isDark
          ? AppColors.welcomeCardGradientSlateDark
          : AppColors.welcomeCardGradientBlueLight,
    );
  }

  // Glassmorphism container decoration
  static BoxDecoration glassContainer(bool isDark) {
    return BoxDecoration(
      color: Colors.transparent,
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      borderRadius: AppDimensions.borderRadius24,
    );
  }

  // Greeting tag decoration
  static BoxDecoration greetingTag = BoxDecoration(
    color: Colors.white.withOpacity(0.2),
    borderRadius: AppDimensions.borderRadius20,
    border: Border.all(
      color: Colors.white.withOpacity(0.3),
      width: 1,
    ),
  );

  // Decorative Circle Blob
  static BoxDecoration decorativeBlob(bool isDark, {bool useShadow = false}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(isDark ? 0.05 : 0.2),
      // Only welcome card uses specific opacity logic here, adapting generally
    );
  }

  // 3D/Glass Icon decoration
  static BoxDecoration iconGlassDecoration(bool isDark) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black26 : Colors.blue.shade900.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(5, 10),
        ),
      ],
    );
  }

  // Home Screen background blob
  static BoxDecoration homeBlob(Color color, {double blurRadius = 80, double spreadRadius = 20}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.transparent,
      boxShadow: [
        BoxShadow(
          color: color,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
      ],
    );
  }
}