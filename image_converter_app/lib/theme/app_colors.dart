import 'package:flutter/material.dart';

/// Định nghĩa tất cả màu sắc được sử dụng trong app
class AppColors {
  AppColors._(); // Private constructor để prevent instantiation

  //PRIMARY COLORS

  static const Color primary = Color(0xFF3B82F6); // Blue 500 (Home Screen Primary)
  static const Color primaryDark = Color(0xFF2563EB); // Blue 600
  static const Color secondary = Color(0xFF60A5FA); // Blue 400
  static const Color secondaryDark = Color(0xFF1E40AF); // Blue 800

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
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800 - Main text color

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
  static const Color backgroundDark = Color(0xFF0F172A); // Matches Home Dark Gradient Start
  static Color backgroundLight = const Color(0xFFF0F9FF); // Matches Home Light Gradient Start
  
  // Premium Light Mode Background
  static const Color backgroundLightStart = Color(0xFFF0F9FF);
  static const Color backgroundLightEnd = Color(0xFFE0F2FE);

  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E293B); // Matches Home Dark Blob/Card
  
  // Soft accent colors for Light Mode
  static const Color softBlue = Color(0xFF6366F1);
  static const Color softPurple = Color(0xFF8B5CF6);
  static const Color softOrange = Color(0xFFF97316);
  static const Color softGreen = Color(0xFF22C55E);

  // Common opacity values
  static const double opacity05 = 0.05;
  static const double opacity10 = 0.1;
  static const double opacity15 = 0.15;
  static const double opacity20 = 0.2;
  static const double opacity30 = 0.3;
  static const double opacity50 = 0.5;
  static const double opacity80 = 0.8;
  static const double opacity90 = 0.9;

  //GRADIENTS

  static const LinearGradient primaryGradientLight = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)], // Match Welcome Card
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
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

  // HOME SCREEN BACKGROUND GRADIENTS
  static const LinearGradient homeBackgroundGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)], // Sky Blue Light
  );

  static const LinearGradient homeBackgroundGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Dark Slate
  );

  // WELCOME CARD GRADIENTS
  static const LinearGradient welcomeCardGradientBlueLight = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)], // Primary Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient welcomeCardGradientSlateDark = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ══════════════════════════════════════════════════════════════════
  //                         VIP CROWN COLORS
  // ══════════════════════════════════════════════════════════════════
  
  // Crown màu vàng cho user chưa VIP (hấp dẫn để upgrade)
  static const Color crownGold = Color(0xFFFFD700);
  static const Color crownGoldDark = Color(0xFFDAA520);
  static const Color crownGoldLight = Color(0xFFFFE55C);
  
  // Crown màu viền vàng
  static const Color crownVipBorder = Color(0xFFFFD700);
  
  // Crown shine color
  static const Color crownPlatinumShine = Color(0xFFFFFFFF);
  
  // VIP badge background
  static const Color vipBadgeBackground = Color(0xFF1A1A2E);
  static const Color vipBadgeBackgroundLight = Color(0xFFFFF8E1);
  
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

  // ══════════════════════════════════════════════════════════════════
  //                    PREMIUM VIP CROWN COLORS (PRO MAX)
  // ══════════════════════════════════════════════════════════════════

  // Liquid Glass Effects
  static const Color liquidGlassCore = Color(0xFFFFFFFF);
  static const Color liquidGlassEdge = Color(0x40FFFFFF);
  static const Color liquidGlassFrost = Color(0x20FFFFFF);

  // Iridescent Diamond Colors
  static const Color iridescentPink = Color(0xFFFF6B9D);
  static const Color iridescentPurple = Color(0xFFBF5AF2);
  static const Color iridescentBlue = Color(0xFF64D2FF);
  static const Color iridescentCyan = Color(0xFF5CE1E6);
  static const Color iridescentGold = Color(0xFFFFE66D);

  // Premium Luxury Gold Palette
  static const Color luxuryGoldDeep = Color(0xFFB8860B);     // Dark Goldenrod
  static const Color luxuryGoldRich = Color(0xFFDAA520);     // Goldenrod
  static const Color luxuryGoldPrimary = Color(0xFFFFD700);  // Gold
  static const Color luxuryGoldLight = Color(0xFFFFE55C);    // Light Gold
  static const Color luxuryGoldShine = Color(0xFFFFF8DC);    // Cream White
  static const Color luxuryGoldGlow = Color(0xFFFFF4E0);     // Soft Glow

  // VIP Platinum Colors
  static const Color platinumDark = Color(0xFF8B8B99);
  static const Color platinumMid = Color(0xFFB8B8CC);
  static const Color platinumLight = Color(0xFFE0E0F0);
  static const Color platinumShine = Color(0xFFF5F5FF);
  static const Color platinumGlow = Color(0xFFFFFFFF);

  // Premium Gradients for VIP Crown
  static const LinearGradient luxuryGoldGradient = LinearGradient(
    colors: [luxuryGoldGlow, luxuryGoldPrimary, luxuryGoldRich, luxuryGoldDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  static const LinearGradient iridescentGradient = LinearGradient(
    colors: [iridescentPink, iridescentPurple, iridescentBlue, iridescentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient diamondShineGradient = LinearGradient(
    colors: [platinumGlow, iridescentBlue, platinumShine, iridescentPurple, platinumGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  // Aura/Glow Gradients
  static const RadialGradient vipAuraGlow = RadialGradient(
    colors: [
      Color(0x40FFD700),  // Gold center glow
      Color(0x20FFD700),  // Mid glow
      Color(0x00FFD700),  // Transparent edge
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const RadialGradient diamondAuraGlow = RadialGradient(
    colors: [
      Color(0x60FFFFFF),  // White center
      Color(0x30BF5AF2),  // Purple mid
      Color(0x0064D2FF),  // Blue edge
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Crown Container Gradients
  static const LinearGradient crownContainerGoldGradient = LinearGradient(
    colors: [
      Color(0x30FFD700),
      Color(0x10FFD700),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient crownContainerPlatinumGradient = LinearGradient(
    colors: [
      Color(0x30FFFFFF),
      Color(0x10E0E0F0),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}