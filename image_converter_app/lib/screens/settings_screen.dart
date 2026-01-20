import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../blocs/theme_cubit.dart';
import '../blocs/language_cubit.dart';
import '../blocs/font_size_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : AppColors.backgroundLight,

      // --- AppBar sử dụng style thống nhất ---
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.getPrimaryGradient(isDark),
          ),
          child: SafeArea(
            child: Padding(
              padding: AppDimensions.paddingH16,
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // Title
                  Expanded(
                    child: Center(
                      child: Text(
                        lang.settings ?? "Cài đặt",
                        style: const TextStyle(
                          fontWeight: AppTextStyles.weightBold,
                          color: AppColors.white,
                          fontSize: AppTextStyles.fontSize20,
                        ),
                      ),
                    ),
                  ),
                  // Placeholder để cân bằng layout
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: AppDimensions.paddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION: Hiển thị ---
            _buildSectionTitle(lang.display ?? "Hiển thị", theme),
            const SizedBox(height: AppDimensions.spacing12),

            // --- 1. DARK MODE ---
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) {
                bool isDarkMode = mode == ThemeMode.dark;
                return _buildCard(
                  isDark: isDark,
                  theme: theme,
                  child: SwitchListTile(
                    contentPadding: AppDimensions.paddingH16V8,
                    secondary: Container(
                      padding: AppDimensions.paddingAll10,
                      decoration: BoxDecoration(
                        color: (isDarkMode ? AppColors.purple : AppColors.orange)
                            .withOpacity(isDark ? AppColors.opacity20 : AppColors.opacity10),
                        borderRadius: AppDimensions.borderRadius12,
                      ),
                      child: Icon(
                        isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: isDarkMode
                            ? (isDark ? AppColors.purple300 : AppColors.purple)
                            : (isDark ? AppColors.orange300 : AppColors.orange),
                        size: AppDimensions.iconSizeRegular,
                      ),
                    ),
                    title: Text(
                      lang.darkMode ?? "Chế độ tối",
                      style: AppTextStyles.subtitleBold,
                    ),
                    subtitle: Text(
                      isDarkMode ? (lang.enabled ?? "Đang bật") : (lang.disabled ?? "Đang tắt"),
                      style: TextStyle(
                        fontSize: AppTextStyles.fontSize13,
                        color: AppTheme.getSecondaryTextColor(isDark),
                      ),
                    ),
                    value: isDarkMode,
                    activeColor: isDark ? AppColors.purple300 : AppColors.purple,
                    onChanged: (val) {
                      context.read<ThemeCubit>().toggleTheme(val);
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: AppDimensions.spacing12),

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
                    padding: AppDimensions.paddingAll16,
                    child: Column(
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: AppDimensions.paddingAll10,
                              decoration: BoxDecoration(
                                color: AppColors.blue.withOpacity(isDark ? AppColors.opacity20 : AppColors.opacity10),
                                borderRadius: AppDimensions.borderRadius12,
                              ),
                              child: Icon(
                                Icons.text_fields,
                                color: isDark ? AppColors.blue300 : AppColors.blue,
                                size: AppDimensions.iconSizeRegular,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacing16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.fontSize ?? "Cỡ chữ",
                                    style: AppTextStyles.subtitleBold,
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: AppDimensions.paddingH8V2,
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withOpacity(AppColors.opacity15),
                                          borderRadius: AppDimensions.borderRadius6,
                                        ),
                                        child: Text(
                                          "${(clampedSize * 100).round()}%",
                                          style: TextStyle(
                                            fontSize: AppTextStyles.fontSize13,
                                            color: isDark ? AppColors.blue300 : theme.primaryColor,
                                            fontWeight: AppTextStyles.weightBold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppDimensions.spacing8),
                                      Text(
                                        "(${lang.max ?? "Tối đa"}: 120%)",
                                        style: TextStyle(
                                          fontSize: AppTextStyles.fontSize11,
                                          color: AppColors.grey500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppDimensions.spacing16),

                        // Slider
                        Row(
                          children: [
                            Text(
                              "80%",
                              style: TextStyle(
                                fontSize: AppTextStyles.fontSize11,
                                color: AppColors.grey500,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: isDark ? AppColors.blue300 : theme.primaryColor,
                                  inactiveTrackColor: isDark ? AppColors.grey700 : AppColors.grey300,
                                  thumbColor: isDark ? AppColors.blue300 : theme.primaryColor,
                                  overlayColor: theme.primaryColor.withOpacity(AppColors.opacity20),
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: AppDimensions.sliderThumbRadius),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: AppDimensions.sliderOverlayRadius),
                                  trackHeight: AppDimensions.sliderTrackHeight,
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
                                fontSize: AppTextStyles.fontSize11,
                                color: AppColors.grey500,
                                fontWeight: AppTextStyles.weightMedium,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppDimensions.spacing12),

                        // Preset Buttons
                        Text(
                          lang.quickSelect ?? "Chọn nhanh:",
                          style: TextStyle(
                            fontSize: AppTextStyles.fontSize12,
                            color: AppTheme.getSecondaryTextColor(isDark),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing8),
                        Row(
                          children: presets.map((preset) {
                            final isSelected = (clampedSize * 10).round() == (preset * 10).round();
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => context.read<FontSizeCubit>().changeSize(preset),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  padding: AppDimensions.paddingV10,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark ? AppColors.blue300 : theme.primaryColor)
                                        : (isDark ? AppColors.grey800 : AppColors.grey100),
                                    borderRadius: AppDimensions.borderRadius10,
                                    border: Border.all(
                                      color: isSelected
                                          ? (isDark ? AppColors.blue300 : theme.primaryColor)
                                          : (isDark ? AppColors.grey700 : AppColors.grey300),
                                      width: isSelected ? AppDimensions.borderWidth2 : AppDimensions.borderWidth1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "${(preset * 100).round()}%",
                                        style: TextStyle(
                                          fontSize: AppTextStyles.fontSize12,
                                          fontWeight: isSelected ? AppTextStyles.weightBold : AppTextStyles.weightMedium,
                                          color: isSelected
                                              ? (isDark ? AppColors.black : AppColors.white)
                                              : null,
                                        ),
                                      ),
                                      if (preset == 1.0)
                                        Text(
                                          lang.defaultSize ?? "Mặc định",
                                          style: TextStyle(
                                            fontSize: AppTextStyles.fontSize9,
                                            color: isSelected
                                                ? (isDark ? Colors.black54 : Colors.white70)
                                                : AppColors.grey500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: AppDimensions.spacing14),

                        // Preview
                        Container(
                          width: double.infinity,
                          padding: AppDimensions.paddingAll14,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : AppColors.grey50,
                            borderRadius: AppDimensions.borderRadius12,
                            border: Border.all(
                              color: isDark ? AppColors.grey800 : AppColors.grey200,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.visibility_rounded,
                                    size: AppDimensions.iconSizeSmall,
                                    color: AppColors.grey500,
                                  ),
                                  const SizedBox(width: AppDimensions.spacing6),
                                  Text(
                                    lang.preview ?? "Xem trước",
                                    style: TextStyle(
                                      fontSize: AppTextStyles.fontSize11,
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.spacing8),
                              Text(
                                "Aa Bb Cc 123",
                                style: TextStyle(
                                  fontSize: AppTextStyles.fontSize16 * clampedSize,
                                  fontWeight: AppTextStyles.weightMedium,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacing4),
                              Text(
                                lang.sampleText ?? "Đây là văn bản mẫu",
                                style: TextStyle(
                                  fontSize: AppTextStyles.fontSize14 * clampedSize,
                                  color: AppTheme.getSecondaryTextColor(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppDimensions.spacing10),

                        // Hint
                        Text(
                          lang.fontSizeHint ?? "Kéo thanh trượt để thay đổi cỡ chữ",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.getSecondaryTextColor(isDark),
                            fontSize: AppTextStyles.fontSize12,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Max warning
                        if ((clampedSize * 10).round() == 12)
                          Padding(
                            padding: const EdgeInsets.only(top: AppDimensions.spacing10),
                            child: Container(
                              padding: AppDimensions.paddingH12V8,
                              decoration: BoxDecoration(
                                color: AppColors.orange.withOpacity(isDark ? AppColors.opacity20 : AppColors.opacity10),
                                borderRadius: AppDimensions.borderRadius8,
                                border: Border.all(
                                  color: (isDark ? AppColors.orange300 : AppColors.orange).withOpacity(AppColors.opacity50),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: AppDimensions.iconSizeMedium,
                                    color: isDark ? AppColors.orange300 : AppColors.orange700,
                                  ),
                                  const SizedBox(width: AppDimensions.spacing6),
                                  Text(
                                    lang.maxLimitReached ?? "Đã đạt giới hạn tối đa",
                                    style: TextStyle(
                                      fontSize: AppTextStyles.fontSize12,
                                      color: isDark ? AppColors.orange300 : AppColors.orange700,
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

            const SizedBox(height: AppDimensions.spacing30),

            // --- SECTION: Ngôn ngữ ---
            _buildSectionTitle(lang.languageRegion ?? "Ngôn ngữ & Khu vực", theme),
            const SizedBox(height: AppDimensions.spacing12),

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
                        height: AppDimensions.borderWidth1,
                        indent: 60,
                        endIndent: AppDimensions.spacing16,
                        color: AppTheme.getBorderColor(isDark),
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

            const SizedBox(height: AppDimensions.spacing30),
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
          width: AppDimensions.spacing4,
          height: AppDimensions.spacing20,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: AppDimensions.borderRadius2,
          ),
        ),
        const SizedBox(width: AppDimensions.spacing10),
        Text(
          title,
          style: TextStyle(
            fontSize: AppTextStyles.fontSize18,
            fontWeight: AppTextStyles.weightBold,
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
        borderRadius: AppDimensions.borderRadius15,
        border: isDark
            ? Border.all(color: AppColors.grey800, width: AppDimensions.borderWidth1)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(isDark ? AppColors.opacity30 : AppColors.opacity05),
            blurRadius: AppDimensions.blurRadius10,
            offset: const Offset(0, 2),
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
      borderRadius: AppDimensions.borderRadius12,
      child: Padding(
        padding: AppDimensions.paddingH16V14,
        child: Row(
          children: [
            Container(
              width: AppDimensions.avatarSizeSmall,
              height: AppDimensions.avatarSizeSmall,
              decoration: BoxDecoration(
                color: isDark ? AppColors.grey800 : AppColors.grey100,
                borderRadius: AppDimensions.borderRadius10,
              ),
              child: Center(
                child: Text(flag, style: const TextStyle(fontSize: AppTextStyles.fontSize22)),
              ),
            ),
            const SizedBox(width: AppDimensions.spacing14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitleBold,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppTextStyles.fontSize12,
                      color: AppTheme.getSecondaryTextColor(isDark),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: AppDimensions.iconSizeRegular,
              height: AppDimensions.iconSizeRegular,
              decoration: BoxDecoration(
                color: isSelected ? theme.primaryColor : AppColors.white.withOpacity(0),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.primaryColor
                      : (isDark ? AppColors.grey600 : AppColors.grey400),
                  width: AppDimensions.borderWidth2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: AppDimensions.iconSizeSmall, color: AppColors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}