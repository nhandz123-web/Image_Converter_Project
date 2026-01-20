import 'package:flutter/material.dart';

/// Định nghĩa tất cả màu sắc được sử dụng trong app
class AppColors {
  AppColors._(); // Private constructor để prevent instantiation

  //PRIMARY COLORS

  static const Color primary = Color(0xFF667eea);
  static const Color primaryDark = Color(0xFF1A237E);
  static const Color secondary = Color(0xFF764ba2);
  static const Color secondaryDark = Color(0xFF0D47A1);

  //FEATURE COLORS

  static const Color purple = Colors.purple;
  static const Color blue = Colors.blue;
  static const Color red = Colors.red;
  static const Color redAccent = Colors.redAccent;
  static const Color orange = Colors.orange;
  static const Color green = Colors.green;
  static const Color teal = Colors.teal;
  static const Color pink = Colors.pink;

  // Shades for dark mode
  static final Color purple300 = Colors.purple[300]!;
  static final Color blue300 = Colors.blue[300]!;
  static final Color blue400 = Colors.blue[400]!;
  static final Color blue700 = Colors.blue[700]!;
  static final Color blue900 = Colors.blue[900]!;
  static final Color orange300 = Colors.orange[300]!;
  static final Color orange700 = Colors.orange[700]!;
  static final Color purple400 = Colors.purple[400]!;

  //NEUTRAL COLORS

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color black87 = Colors.black87;

  // Grey shades
  static const Color grey = Colors.grey;
  static final Color grey50 = Colors.grey[50]!;
  static final Color grey100 = Colors.grey[100]!;
  static final Color grey200 = Colors.grey[200]!;
  static final Color grey300 = Colors.grey[300]!;
  static final Color grey400 = Colors.grey[400]!;
  static final Color grey500 = Colors.grey[500]!;
  static final Color grey600 = Colors.grey[600]!;
  static final Color grey700 = Colors.grey[700]!;
  static final Color grey800 = Colors.grey[800]!;
  static final Color grey850 = Colors.grey[850]!;
  static final Color grey900 = Colors.grey[900]!;

  //STATUS COLORS

  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;

  // BACKGROUND COLORS
  static const Color backgroundDark = Color(0xFF121212);
  static Color backgroundLight = Colors.grey[50]!;
  
  // Premium Light Mode Background
  static const Color backgroundLightStart = Color(0xFFF8FAFF);
  static const Color backgroundLightEnd = Color(0xFFE8EEF9);

  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E1E1E);
  
  // Soft accent colors for Light Mode
  static const Color softBlue = Color(0xFF6366F1);
  static const Color softPurple = Color(0xFF8B5CF6);
  static const Color softPink = Color(0xFFEC4899);
  static const Color softTeal = Color(0xFF14B8A6);
  static const Color softOrange = Color(0xFFF97316);
  static const Color softGreen = Color(0xFF22C55E);

  //OPACITY HELPERS

  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Common opacity values
  static const double opacity05 = 0.05;
  static const double opacity10 = 0.1;
  static const double opacity15 = 0.15;
  static const double opacity20 = 0.2;
  static const double opacity30 = 0.3;
  static const double opacity40 = 0.4;
  static const double opacity50 = 0.5;
  static const double opacity70 = 0.7;
  static const double opacity80 = 0.8;
  static const double opacity90 = 0.9;

  //GRADIENTS

  static const LinearGradient primaryGradientLight = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient welcomeCardGradientLight = const LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient welcomeCardGradientDark = LinearGradient(
    colors: [Colors.blue[900]!, Colors.blue[700]!],
  );
  
  // ✅ MỚI: Background gradient cho Light Mode
  static const LinearGradient backgroundGradientLight = LinearGradient(
    colors: [backgroundLightStart, backgroundLightEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient backgroundGradientDark = LinearGradient(
    colors: [backgroundDark, Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Premium AppBar gradient cho Light Mode (mềm mại hơn)
  static const LinearGradient appBarGradientLight = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient appBarGradientDark = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF283593)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  // ══════════════════════════════════════════════════════════════════
  //                         VIP CROWN COLORS
  // ══════════════════════════════════════════════════════════════════
  
  // Crown màu vàng cho user chưa VIP (hấp dẫn để upgrade)
  static const Color crownGold = Color(0xFFFFD700);
  static const Color crownGoldDark = Color(0xFFDAA520);
  static const Color crownGoldLight = Color(0xFFFFE55C);
  
  // Crown màu vàng đậm cho VIP user (cao cấp, nổi bật)
  static const Color crownVipGold = Color(0xFFFFD700);       // Vàng chính
  static const Color crownVipGoldDark = Color(0xFFB8860B);   // Vàng đậm (DarkGoldenrod)
  static const Color crownVipGoldShine = Color(0xFFFFF8DC);  // Vàng kem sáng (Cornsilk)
  static const Color crownVipBorder = Color(0xFFFFD700);     // Viền vàng
  
  // Legacy platinum colors (giữ lại để tương thích)
  static const Color crownPlatinum = Color(0xFFF5F5F5);
  static const Color crownPlatinumShine = Color(0xFFFFFFFF);
  
  // VIP badge background
  static const Color vipBadgeBackground = Color(0xFF1A1A2E);
  static const Color vipBadgeBackgroundLight = Color(0xFFFFF8E1);
  
  // Gradient cho crown chưa VIP (shimmer effect - vàng nhạt hơn)
  static const LinearGradient crownGoldGradient = LinearGradient(
    colors: [Color(0xFFFFE55C), Color(0xFFFFD700), Color(0xFFDAA520)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Gradient cho crown VIP (vàng đậm, nổi bật hơn)
  static const LinearGradient crownVipGradient = LinearGradient(
    colors: [Color(0xFFFFF8DC), Color(0xFFFFD700), Color(0xFFDAA520)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Gradient cho crown VIP - Dark mode (sáng hơn)
  static const LinearGradient crownVipGradientDark = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFD700), Color(0xFFFFE55C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}