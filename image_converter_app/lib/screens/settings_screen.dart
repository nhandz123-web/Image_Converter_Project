import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
// Import các Cubit quản lý trạng thái
import '../blocs/theme_cubit.dart';
import '../blocs/language_cubit.dart';
import '../blocs/font_size_cubit.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Lấy file ngôn ngữ
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.settings), // "Cài đặt"
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionTitle("Hiển thị"),

          // --- 1. DARK MODE (Dùng BlocBuilder để nghe trạng thái Theme) ---
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              bool isDark = mode == ThemeMode.dark;
              return SwitchListTile(
                title: Text("Chế độ tối (Dark Mode)"),
                subtitle: Text(isDark ? "Đang bật" : "Đang tắt"),
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                value: isDark,
                onChanged: (val) {
                  // Gọi Cubit để đổi Theme thật
                  context.read<ThemeCubit>().toggleTheme(val);
                },
              );
            },
          ),

          // --- 2. CỠ CHỮ (Dùng BlocBuilder để nghe trạng thái FontSize) ---
          BlocBuilder<FontSizeCubit, double>(
            builder: (context, currentSize) {
              return Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.text_fields),
                    title: Text("Cỡ chữ"),
                    subtitle: Text("${(currentSize * 100).round()}%"),
                  ),
                  Slider(
                    value: currentSize,
                    min: 0.8, // 80%
                    max: 1.5, // 150%
                    divisions: 7,
                    label: "${(currentSize * 100).round()}%",
                    onChanged: (val) {
                      // Gọi Cubit để đổi cỡ chữ thật
                      context.read<FontSizeCubit>().changeSize(val);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Kéo thanh trượt để xem chữ to nhỏ thế nào",
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            },
          ),

          Divider(height: 30),
          _buildSectionTitle("Ngôn ngữ & Khu vực"),

          // --- 3. NGÔN NGỮ (Dùng BlocBuilder để nghe trạng thái Language) ---
          BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              return Column(
                children: [
                  RadioListTile<String>(
                    title: Text("Tiếng Việt"),
                    value: 'vi',
                    groupValue: locale.languageCode,
                    secondary: Text("🇻🇳", style: TextStyle(fontSize: 20)),
                    onChanged: (val) {
                      context.read<LanguageCubit>().toVietnamese();
                    },
                  ),
                  RadioListTile<String>(
                    title: Text("English"),
                    value: 'en',
                    groupValue: locale.languageCode,
                    secondary: Text("🇺🇸", style: TextStyle(fontSize: 20)),
                    onChanged: (val) {
                      context.read<LanguageCubit>().toEnglish();
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.blue, // Hoặc dùng Theme.of(context).primaryColor
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}