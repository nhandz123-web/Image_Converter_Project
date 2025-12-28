import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../blocs/theme_cubit.dart';
import '../blocs/language_cubit.dart';
import '../blocs/font_size_cubit.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.grey[50],

      // --- AppBar với Gradient ---
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          lang.settings ?? "Cài đặt",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Color(0xFF1A237E), Color(0xFF0D47A1)]
                  : [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION: Hiển thị ---
            _buildSectionTitle(lang.display ?? "Hiển thị", theme),
            SizedBox(height: 12),

            // --- 1. DARK MODE ---
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) {
                bool isDarkMode = mode == ThemeMode.dark;
                return _buildCard(
                  isDark: isDark,
                  theme: theme,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    secondary: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDarkMode ? Colors.purple : Colors.orange)
                            .withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: isDarkMode
                            ? (isDark ? Colors.purple[300] : Colors.purple)
                            : (isDark ? Colors.orange[300] : Colors.orange),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      lang.darkMode ?? "Chế độ tối",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      isDarkMode ? (lang.enabled ?? "Đang bật") : (lang.disabled ?? "Đang tắt"),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    value: isDarkMode,
                    activeColor: isDark ? Colors.purple[300] : Colors.purple,
                    onChanged: (val) {
                      context.read<ThemeCubit>().toggleTheme(val);
                    },
                  ),
                );
              },
            ),

            SizedBox(height: 12),

            // --- 2. CỠ CHỮ (MAX 120%) ---
            BlocBuilder<FontSizeCubit, double>(
              builder: (context, currentSize) {
                // ★ GIỚI HẠN 80% - 120%
                final double clampedSize = currentSize.clamp(0.8, 1.2);
                final List<double> presets = [0.8, 0.9, 1.0, 1.1, 1.2];

                return _buildCard(
                  isDark: isDark,
                  theme: theme,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.text_fields,
                                color: isDark ? Colors.blue[300] : Colors.blue,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.fontSize ?? "Cỡ chữ",
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "${(clampedSize * 100).round()}%",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? Colors.blue[300] : theme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "(${lang.max ?? "Tối đa"}: 120%)",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Slider
                        Row(
                          children: [
                            Text(
                              "80%",
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: isDark ? Colors.blue[300] : theme.primaryColor,
                                  inactiveTrackColor: isDark ? Colors.grey[700] : Colors.grey[300],
                                  thumbColor: isDark ? Colors.blue[300] : theme.primaryColor,
                                  overlayColor: theme.primaryColor.withOpacity(0.2),
                                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
                                  overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
                                  trackHeight: 6,
                                ),
                                child: Slider(
                                  value: clampedSize,
                                  min: 0.8,
                                  max: 1.2,  // ★ MAX = 120%
                                  divisions: 4,
                                  label: "${(clampedSize * 100).round()}%",
                                  onChanged: (val) {
                                    context.read<FontSizeCubit>().changeSize(val);
                                  },
                                ),
                              ),
                            ),
                            Text(
                              "120%",
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Preset Buttons
                        Text(
                          lang.quickSelect ?? "Chọn nhanh:",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: presets.map((preset) {
                            final isSelected = (clampedSize * 10).round() == (preset * 10).round();
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => context.read<FontSizeCubit>().changeSize(preset),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  margin: EdgeInsets.symmetric(horizontal: 3),
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark ? Colors.blue[300] : theme.primaryColor)
                                        : (isDark ? Colors.grey[800] : Colors.grey[100]),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? (isDark ? Colors.blue[300]! : theme.primaryColor)
                                          : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "${(preset * 100).round()}%",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected
                                              ? (isDark ? Colors.black : Colors.white)
                                              : null,
                                        ),
                                      ),
                                      if (preset == 1.0)
                                        Text(
                                          lang.defaultSize ?? "Mặc định",
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isSelected
                                                ? (isDark ? Colors.black54 : Colors.white70)
                                                : (isDark ? Colors.grey[500] : Colors.grey[500]),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 14),

                        // Preview
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.visibility_rounded,
                                    size: 14,
                                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    lang.preview ?? "Xem trước",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Aa Bb Cc 123",
                                style: TextStyle(
                                  fontSize: 16 * clampedSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                lang.sampleText ?? "Đây là văn bản mẫu",
                                style: TextStyle(
                                  fontSize: 14 * clampedSize,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 10),

                        // Hint
                        Text(
                          lang.fontSizeHint ?? "Kéo thanh trượt để thay đổi cỡ chữ",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Max warning
                        if ((clampedSize * 10).round() == 12)
                          Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (isDark ? Colors.orange[300]! : Colors.orange).withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 16,
                                    color: isDark ? Colors.orange[300] : Colors.orange[700],
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    lang.maxLimitReached ?? "Đã đạt giới hạn tối đa",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.orange[300] : Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 30),

            // --- SECTION: Ngôn ngữ ---
            _buildSectionTitle(lang.languageRegion ?? "Ngôn ngữ & Khu vực", theme),
            SizedBox(height: 12),

            // --- 3. NGÔN NGỮ ---
            BlocBuilder<LanguageCubit, Locale>(
              builder: (context, locale) {
                return _buildCard(
                  isDark: isDark,
                  theme: theme,
                  child: Column(
                    children: [
                      _buildLanguageTile(
                        context: context,
                        flag: "🇻🇳",
                        title: "Tiếng Việt",
                        subtitle: "Vietnamese",
                        value: 'vi',
                        groupValue: locale.languageCode,
                        isDark: isDark,
                        theme: theme,
                        onTap: () => context.read<LanguageCubit>().toVietnamese(),
                      ),
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 16,
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                      ),
                      _buildLanguageTile(
                        context: context,
                        flag: "🇺🇸",
                        title: "English",
                        subtitle: "Tiếng Anh",
                        value: 'en',
                        groupValue: locale.languageCode,
                        isDark: isDark,
                        theme: theme,
                        onTap: () => context.read<LanguageCubit>().toEnglish(),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //                      HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required bool isDark,
    required ThemeData theme,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: isDark
            ? Border.all(color: Colors.grey[800]!, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLanguageTile({
    required BuildContext context,
    required String flag,
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(flag, style: TextStyle(fontSize: 22)),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? theme.primaryColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.primaryColor
                      : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}