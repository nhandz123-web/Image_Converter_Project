import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageCubit extends Cubit<Locale> {
  // Nhận code ngôn ngữ ban đầu (vn hoặc en)
  LanguageCubit({String languageCode = 'vi'}) : super(Locale(languageCode));

  void toVietnamese() => _changeLanguage('vi');
  void toEnglish() => _changeLanguage('en');

  void _changeLanguage(String code) async {
    emit(Locale(code));
    // Lưu vào bộ nhớ
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
  }
}