import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_screen.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../blocs/font_size_cubit.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/language_cubit.dart';
import '../blocs/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Biến tắt để gọi cho nhanh
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(lang.settings)), // Dùng lang.settings thay cho chữ cứng
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoggedOut) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
            );
          }
        },
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("Người dùng"),
              accountEmail: Text("user@example.com"),
              currentAccountPicture: CircleAvatar(child: Icon(Icons.person)),
            ),
            SizedBox(height: 20),

            // --- PHẦN CHỌN NGÔN NGỮ ---
            Text(lang.language, style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                // Nút Tiếng Việt
                Expanded(
                  child: RadioListTile<String>(
                    title: Text("Tiếng Việt"),
                    value: 'vi',
                    groupValue: Localizations.localeOf(context).languageCode,
                    onChanged: (value) {
                      context.read<LanguageCubit>().toVietnamese();
                    },
                  ),
                ),
                // Nút Tiếng Anh
                Expanded(
                  child: RadioListTile<String>(
                    title: Text("English"),
                    value: 'en',
                    groupValue: Localizations.localeOf(context).languageCode,
                    onChanged: (value) {
                      context.read<LanguageCubit>().toEnglish();
                    },
                  ),
                ),
              ],
            ),
            Divider(),
            // ---------------------------
            // --- PHẦN CHỈNH CỠ CHỮ ---
            Text("Cỡ chữ", style: TextStyle(fontWeight: FontWeight.bold)),

            // BlocBuilder để thanh trượt tự cập nhật vị trí khi kéo
            BlocBuilder<FontSizeCubit, double>(
              builder: (context, currentSize) {
                return Column(
                  children: [
                    // Thanh trượt
                    Slider(
                      value: currentSize,
                      min: 0.8, // Nhỏ nhất (80%)
                      max: 1.5, // To nhất (150%)
                      divisions: 7, // Chia làm 7 nấc cho dễ chọn
                      label: "${(currentSize * 100).round()}%", // Hiện số % khi kéo
                      onChanged: (value) {
                        // Gửi cỡ chữ mới vào Cubit
                        context.read<FontSizeCubit>().changeSize(value);
                      },
                    ),
                    // Hiển thị text xem trước
                    Text(
                      "Kéo để xem chữ to nhỏ thế nào",
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                );
              },
            ),
            Divider(),
            // --- PHẦN CHẾ ĐỘ TỐI (DARK MODE) ---
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) {
                return SwitchListTile(
                  title: Text("Chế độ tối", style: TextStyle(fontWeight: FontWeight.bold)),
                  secondary: Icon(Icons.dark_mode), // Icon mặt trăng
                  value: mode == ThemeMode.dark, // Nếu đang là Dark thì bật switch
                  onChanged: (bool value) {
                    // Gửi lệnh đổi màu
                    context.read<ThemeCubit>().toggleTheme(value);
                  },
                );
              },
            ),
            Text(lang.storage_used, style: TextStyle(fontWeight: FontWeight.bold)),
            // ... (Phần thanh progress giữ nguyên)

            SizedBox(height: 50),

            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(lang.logout, style: TextStyle(color: Colors.red)), // Dùng lang.logout
              onTap: () {
                context.read<AuthBloc>().add(LogoutRequested());
              },
            ),
          ],
        ),
      ),
    );
  }
}