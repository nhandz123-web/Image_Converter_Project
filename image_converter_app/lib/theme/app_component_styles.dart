import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

/// Component styles cho Glassmorphism UI System
/// Các widget helper và decoration factories cho các màn hình trong app
class AppComponentStyles {
  AppComponentStyles._();

  // ══════════════════════════════════════════════════════════════════════════
  //                         GLASS CARD DECORATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Glass container decoration tiêu chuẩn với border radius 24
  /// Sử dụng cho: ProfileScreen, SettingsScreen
  static BoxDecoration glassContainer({
    required bool isDark,
    double borderRadius = 24,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
        width: 1,
      ),
      boxShadow: withShadow ? [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ] : null,
    );
  }

  /// Glass card decoration cho Settings Screen với border radius 20
  static BoxDecoration glassCard({
    required bool isDark,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      color: isDark ? AppColors.cardDark.withOpacity(0.6) : Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
        width: 1,
      ),
      boxShadow: [
        if (!isDark)
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
      ],
    );
  }

  /// Glass container cho File Card (DownloadedFilesScreen)
  static BoxDecoration fileCard({
    required bool isDark,
    required bool isSelected,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      color: isSelected
          ? (isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.1))
          : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6)),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isSelected
            ? AppColors.primary
            : (isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5)),
        width: isSelected ? 2 : 1,
      ),
    );
  }

  /// Glass decoration cho Modal Bottom Sheet
  static BoxDecoration modalGlass({
    required bool isDark,
    double borderRadius = 30,
  }) {
    return BoxDecoration(
      color: isDark ? AppColors.cardDark.withOpacity(0.9) : AppColors.white.withOpacity(0.95),
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      border: Border(
        top: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.6),
          width: 1,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 20,
          spreadRadius: 5,
        ),
      ],
    );
  }

  /// Bottom sheet background decoration (ImageSourceModal)
  static BoxDecoration bottomSheetGlass({
    required bool isDark,
    double borderRadius = 30,
  }) {
    return BoxDecoration(
      color: isDark ? AppColors.cardDark.withOpacity(0.8) : AppColors.white.withOpacity(0.8),
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      border: Border(
        top: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
          width: 1,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, -5),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //                         ICON CONTAINER DECORATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Icon container với màu background nhẹ
  static BoxDecoration iconContainer({
    required Color color,
    required bool isDark,
    double borderRadius = 10,
  }) {
    return BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.1) : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  /// Icon container với gradient (sử dụng trong file cards, source buttons)
  static BoxDecoration iconGradientContainer({
    required List<Color> gradientColors,
    double borderRadius = 24,
    bool withBorder = true,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          gradientColors[0].withOpacity(0.2),
          gradientColors.length > 1 ? gradientColors[1].withOpacity(0.1) : gradientColors[0].withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: withBorder
          ? Border.all(
              color: (gradientColors.length > 1 ? gradientColors[1] : gradientColors[0]).withOpacity(0.3),
              width: 1.5,
            )
          : null,
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: (gradientColors.length > 1 ? gradientColors[1] : gradientColors[0]).withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );
  }

  /// PDF icon decoration (rose color scheme)
  static BoxDecoration pdfIconDecoration({double borderRadius = 12}) {
    return BoxDecoration(
      color: const Color(0xFFF43F5E).withOpacity(0.1),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: const Color(0xFFF43F5E).withOpacity(0.2),
        width: 1,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //                         AVATAR & PROFILE DECORATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Glowing avatar border (ProfileScreen)
  static BoxDecoration glowingAvatarBorder(Color primaryColor) {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [primaryColor.withOpacity(0.5), primaryColor.withOpacity(0.1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //                         PROGRESS BAR DECORATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Progress bar track background
  static BoxDecoration progressTrackBackground({
    required bool isDark,
    double borderRadius = 5,
  }) {
    return BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  /// Progress bar filled portion
  static BoxDecoration progressFill({
    required Color progressColor,
    double borderRadius = 5,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [progressColor.withOpacity(0.7), progressColor],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: progressColor.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //                         BADGE & CHIP DECORATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Badge container (selected count, percentage)
  static BoxDecoration badgeContainer({
    required Color color,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: color.withOpacity(0.3)),
    );
  }

  /// Selection badge (circular) cho MergePdfDialog
  static BoxDecoration selectionBadge({
    required bool isSelected,
    required bool isDark,
  }) {
    return BoxDecoration(
      color: isSelected ? AppColors.primary : Colors.transparent,
      shape: BoxShape.circle,
      border: Border.all(
        color: isSelected ? AppColors.primary : (isDark ? Colors.white38 : Colors.grey[400]!),
        width: 2,
      ),
    );
  }

  /// Info chip container (type badges)
  static BoxDecoration infoChip({
    required bool isDark,
    required bool isPdf,
    double borderRadius = 4,
  }) {
    final chipColor = isPdf ? Colors.red : Colors.blue;
    return BoxDecoration(
      color: chipColor.withOpacity(isDark ? 0.1 : 0.05),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: chipColor.withOpacity(isDark ? 0.3 : 0.2),
        width: 0.5,
      ),
    );
  }

  /// Selected chip decoration (MergePdfDialog - selected file preview)
  static BoxDecoration selectedChip({
    required bool isDark,
  }) {
    return BoxDecoration(
      color: isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppColors.primary.withOpacity(0.5),
        width: 1,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //                         LIST ITEM DECORATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// PDF item decoration (MergePdfDialog)
  static BoxDecoration pdfItemCard({
    required bool isDark,
    required bool isSelected,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: isSelected
          ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.1)
          : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isSelected
            ? AppColors.primary
            : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!),
        width: isSelected ? 2 : 1,
      ),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ]
          : [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
    );
  }

  /// Language tile container
  static BoxDecoration languageTileFlag({
    required bool isDark,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //                         BUTTON DECORATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Merge button shadow (when enabled)
  static BoxDecoration mergeButtonShadow({
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //                         DIVIDER & SEPARATOR
  // ══════════════════════════════════════════════════════════════════════════

  /// Divider color based on theme
  static Color dividerColor(bool isDark) {
    return isDark ? Colors.white10 : Colors.black.withOpacity(0.05);
  }

  /// Drag handle decoration (for bottom sheets)
  static BoxDecoration dragHandle(bool isDark) {
    return BoxDecoration(
      color: isDark ? Colors.white24 : Colors.grey[300],
      borderRadius: BorderRadius.circular(2),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //                         EMPTY STATE DECORATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Empty state icon container
  static BoxDecoration emptyStateIcon({
    required bool isDark,
    double size = 80,
  }) {
    return BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.blue.withOpacity(0.05),
      shape: BoxShape.circle,
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        width: 1,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //                         PREVIEW BOX DECORATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Preview box decoration (Settings font size preview)
  static BoxDecoration previewBox({
    required bool isDark,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey[50],
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark ? Colors.white10 : Colors.grey[200]!,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //                         DIALOG DECORATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Dialog icon container
  static BoxDecoration dialogIconContainer({
    required Color color,
    double borderRadius = 8,
  }) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //                       CHECK INDICATOR DECORATION
  // ══════════════════════════════════════════════════════════════════════════

  /// Check indicator (Language selector)
  static const BoxDecoration checkIndicator = BoxDecoration(
    color: AppColors.primary,
    shape: BoxShape.circle,
  );
}

/// Widget helpers tái sử dụng
class AppWidgetHelpers {
  AppWidgetHelpers._();

  /// Tạo glass container widget với BackdropFilter
  static Widget glassContainer({
    required Widget child,
    required bool isDark,
    double borderRadius = 24,
    double blurSigma = 10,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: AppComponentStyles.glassContainer(isDark: isDark, borderRadius: borderRadius),
          child: child,
        ),
      ),
    );
  }

  /// Tạo glass card widget cho Settings
  static Widget glassCard({
    required Widget child,
    required bool isDark,
    double borderRadius = 20,
    double blurSigma = 10,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: AppComponentStyles.glassCard(isDark: isDark, borderRadius: borderRadius),
          child: child,
        ),
      ),
    );
  }

  /// Drag handle widget cho bottom sheets
  static Widget dragHandle(bool isDark) {
    return Container(
      width: 40,
      height: 4,
      decoration: AppComponentStyles.dragHandle(isDark),
    );
  }
}
