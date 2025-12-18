import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  // Nhận trạng thái ban đầu từ bên ngoài (Main truyền vào)
  ThemeCubit({bool isDark = false}) : super(isDark ? ThemeMode.dark : ThemeMode.light);

  void toggleTheme(bool isDark) async {
    emit(isDark ? ThemeMode.dark : ThemeMode.light);

    // Lưu vào bộ nhớ
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark', isDark);
  }
}