import 'dart:ui';
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
import '../theme/app_styles.dart';
import '../theme/app_component_styles.dart';
import '../widgets/app_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: AppStyles.homeBackground(isDark),
        child: Stack(
          children: [
            // Background Blobs
            if (!isDark) ...[
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: AppStyles.homeBlob(Colors.blue.withOpacity(0.2)),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -50,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: AppStyles.homeBlob(Colors.purple.withOpacity(0.15), blurRadius: 60),
                ),
              ),
            ],

            // Content
            CustomScrollView(
              slivers: [
                AppHeader(
                  title: lang.settings ?? "Cài đặt",
                  showLogo: false,
                  showVipCrown: false,
                  showProfileButton: false,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // --- SECTION: Hiển thị ---
                      _buildSectionHeader(context, lang.display ?? "Hiển thị", Icons.palette_outlined),
                      const SizedBox(height: 16),

                      // --- 1. DARK MODE ---
                      BlocBuilder<ThemeCubit, ThemeMode>(
                        builder: (context, mode) {
                          bool isDarkMode = mode == ThemeMode.dark;
                          return _buildGlassCard(
                            isDark: isDark,
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              secondary: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: AppComponentStyles.iconContainer(
                                  color: isDarkMode ? AppColors.purple : AppColors.orange,
                                  isDark: isDark,
                                  borderRadius: 12,
                                ),
                                child: Icon(
                                  isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                  color: isDarkMode
                                      ? (isDark ? AppColors.purple300 : AppColors.purple)
                                      : (isDark ? AppColors.orange300 : AppColors.orange),
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                lang.darkMode ?? "Chế độ tối",
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              subtitle: Text(
                                isDarkMode ? (lang.enabled ?? "Đang bật") : (lang.disabled ?? "Đang tắt"),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white54 : Colors.grey[600],
                                ),
                              ),
                              value: isDarkMode,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                context.read<ThemeCubit>().toggleTheme(val);
                                // Optional: Add a small delay/animation if needed
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // --- 2. CỠ CHỮ (MAX 120%) ---
                      BlocBuilder<FontSizeCubit, double>(
                        builder: (context, currentSize) {
                          final double clampedSize = currentSize.clamp(0.8, 1.2);
                          final List<double> presets = [0.8, 0.9, 1.0, 1.1, 1.2];

                          return _buildGlassCard(
                            isDark: isDark,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // Header
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: AppComponentStyles.iconContainer(
                                          color: AppColors.blue,
                                          isDark: isDark,
                                          borderRadius: 12,
                                        ),
                                        child: Icon(
                                          Icons.text_fields_rounded,
                                          color: isDark ? AppColors.blue300 : AppColors.blue,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lang.fontSize ?? "Cỡ chữ",
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  "${(clampedSize * 100).round()}%",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "(${lang.max ?? "Tối đa"}: 120%)",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark ? Colors.white38 : Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Slider
                                  Row(
                                    children: [
                                      Text(
                                        "A-",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.white54 : Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            activeTrackColor: AppColors.primary,
                                            inactiveTrackColor: isDark ? Colors.white24 : Colors.grey[200],
                                            thumbColor: AppColors.primary,
                                            overlayColor: AppColors.primary.withOpacity(0.2),
                                            trackHeight: 4,
                                          ),
                                          child: Slider(
                                            value: clampedSize,
                                            min: 0.8,
                                            max: 1.2,
                                            divisions: 4,
                                            label: "${(clampedSize * 100).round()}%",
                                            onChanged: (val) {
                                              context.read<FontSizeCubit>().changeSize(val);
                                            },
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "A+",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Preview Box
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: AppComponentStyles.previewBox(
                                      isDark: isDark,
                                      borderRadius: 12,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "Aa Bb Cc 123",
                                          style: TextStyle(
                                            fontSize: 16 * clampedSize,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.white : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lang.sampleText ?? "Văn bản mẫu",
                                          style: TextStyle(
                                            fontSize: 14 * clampedSize,
                                            color: isDark ? Colors.white54 : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // --- SECTION: Ngôn ngữ ---
                      _buildSectionHeader(context, lang.languageRegion ?? "Ngôn ngữ & Khu vực", Icons.language_rounded),
                      const SizedBox(height: 16),

                      // --- 3. NGÔN NGỮ ---
                      BlocBuilder<LanguageCubit, Locale>(
                        builder: (context, locale) {
                          return _buildGlassCard(
                            isDark: isDark,
                            child: Column(
                              children: [
                                _buildLanguageTile(
                                  flag: "🇻🇳",
                                  title: "Tiếng Việt",
                                  subtitle: "Vietnamese",
                                  value: 'vi',
                                  groupValue: locale.languageCode,
                                  isDark: isDark,
                                  onTap: () => context.read<LanguageCubit>().toVietnamese(),
                                ),
                                Divider(
                                  height: 1,
                                  indent: 72,
                                  endIndent: 0,
                                  color: isDark ? Colors.white10 : Colors.grey[200],
                                ),
                                _buildLanguageTile(
                                  flag: "🇺🇸",
                                  title: "English",
                                  subtitle: "English",
                                  value: 'en',
                                  groupValue: locale.languageCode,
                                  isDark: isDark,
                                  onTap: () => context.read<LanguageCubit>().toEnglish(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return AppWidgetHelpers.glassCard(
      child: child,
      isDark: isDark,
      borderRadius: 20,
    );
  }

  Widget _buildLanguageTile({
    required String flag,
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: AppComponentStyles.languageTileFlag(
                isDark: isDark,
                borderRadius: 12,
              ),
              child: Center(
                child: Text(flag, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: AppComponentStyles.checkIndicator,
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}